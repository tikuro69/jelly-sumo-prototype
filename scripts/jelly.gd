extends RigidBody3D

const VISUAL_RADIUS := 0.86
const CONTACT_REACH := 1.79
const SPRING := 115.0
const DAMPING := 8.0
var is_player := false
var tint := Color("53d9c2")
var spawn_position := Vector3.ZERO
var peers: Array = []
var control_direction := Vector3.ZERO
var compression := 0.0
var compression_speed := 0.0
var pressure_target := 0.0
var push_direction := Vector2.RIGHT
var visual: Node3D
var jelly_material: ShaderMaterial
var tilt := Vector2.ZERO
var tilt_speed := Vector2.ZERO
var previous_velocity := Vector3.ZERO
var pending_reset := false
var ai_clock := 0.0
var ai_index := 0

func _ready() -> void:
    mass = 1.0
    linear_damp = 2.6
    angular_damp = 8.0
    axis_lock_angular_x = true
    axis_lock_angular_y = true
    axis_lock_angular_z = true
    can_sleep = false
    continuous_cd = true
    physics_material_override = PhysicsMaterial.new()
    physics_material_override.friction = 0.12
    physics_material_override.bounce = 0.03
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.72
    collision.shape = shape
    collision.position.y = 0.73
    add_child(collision)
    visual = Node3D.new()
    visual.position.y = 0.73
    add_child(visual)
    jelly_material = ShaderMaterial.new()
    jelly_material.shader = preload("res://shaders/jelly.gdshader")
    jelly_material.set_shader_parameter("body_color", tint)
    _sphere(VISUAL_RADIUS, 1.55, Vector3.ZERO, jelly_material)
    var smooth := StandardMaterial3D.new()
    smooth.albedo_color = tint
    smooth.roughness = 0.29
    _sphere(0.49, 1.15, Vector3(0, 0.58, 0), smooth)
    _sphere(0.35, 0.68, Vector3(0, 1.13, 0), smooth)

func _sphere(radius: float, height: float, offset: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 64
    mesh.rings = 32
    part.mesh = mesh
    part.material_override = material
    part.position = offset
    visual.add_child(part)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if pending_reset:
        state.transform = Transform3D(Basis.IDENTITY, spawn_position)
        state.linear_velocity = Vector3.ZERO
        state.angular_velocity = Vector3.ZERO
        pending_reset = false

func reset_body() -> void:
    pending_reset = true
    compression = 0.0
    compression_speed = 0.0
    tilt = Vector2.ZERO
    tilt_speed = Vector2.ZERO
    previous_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
    if global_position.y < -7.0:
        reset_body()
    ai_clock += delta
    if not is_player:
        var target: RigidBody3D = null
        var nearest := INF
        for peer in peers:
            if peer == self or peer.global_position.y < -0.5:
                continue
            var distance: float = global_position.distance_squared_to(peer.global_position)
            if distance < nearest:
                nearest = distance
                target = peer
        control_direction = Vector3.ZERO
        if target != null:
            var offset: Vector3 = target.global_position - global_position
            offset.y = 0.0
            control_direction = offset.normalized()
            # Short breathing pauses expose the spring release without elaborate AI.
            if fmod(ai_clock + ai_index * 1.1, 5.8) > 4.7:
                control_direction *= 0.12
    if global_position.y > -0.2 and global_position.y < 0.45:
        apply_central_force(control_direction * (22.0 if is_player else 13.5))
    pressure_target = 0.0
    var strongest_direction := push_direction
    for peer in peers:
        if peer == self:
            continue
        var offset: Vector3 = peer.global_position - global_position
        var distance := Vector2(offset.x, offset.z).length()
        if absf(offset.y) > 0.9 or distance >= CONTACT_REACH or distance < 0.01:
            continue
        var direction := Vector2(offset.x, offset.z) / distance
        var pressure := clampf((CONTACT_REACH - distance) * 0.46, 0.0, 0.36)
        if pressure > pressure_target:
            pressure_target = pressure
            strongest_direction = direction
    if pressure_target > 0.005:
        push_direction = push_direction.lerp(strongest_direction, minf(delta * 18.0, 1.0)).normalized()
    compression_speed += ((pressure_target - compression) * SPRING - compression_speed * DAMPING) * delta
    compression += compression_speed * delta
    jelly_material.set_shader_parameter("compression", compression)
    jelly_material.set_shader_parameter("push_direction", push_direction)
    var acceleration := (linear_velocity - previous_velocity) / delta
    previous_velocity = linear_velocity
    var desired_tilt := Vector2(linear_velocity.z, -linear_velocity.x) * 0.035
    desired_tilt += Vector2(acceleration.z, -acceleration.x).limit_length(18.0) * 0.004
    tilt_speed += ((desired_tilt - tilt) * 65.0 - tilt_speed * 7.0) * delta
    tilt += tilt_speed * delta
    visual.rotation = Vector3(tilt.x, 0.0, tilt.y)

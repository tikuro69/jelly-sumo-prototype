extends Node3D

const Jelly = preload("res://scripts/jelly.gd")
var characters: Array = []
var camera: Camera3D

func _ready() -> void:
    _bind_key("move_left", KEY_A)
    _bind_key("move_right", KEY_D)
    _bind_key("move_forward", KEY_W)
    _bind_key("move_back", KEY_S)
    _bind_key("reset", KEY_R)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("182530")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("c5deef")
    environment.environment.ambient_light_energy = 0.35
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -28, 0)
    sun.light_energy = 0.85
    sun.shadow_enabled = true
    add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-30, 140, 0)
    fill.light_color = Color("a6d7ff")
    fill.light_energy = 0.22
    add_child(fill)
    var stage := StaticBody3D.new()
    add_child(stage)
    var stage_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(10, 0.65, 10)
    stage_shape.shape = box
    stage_shape.position.y = -0.325
    stage.add_child(stage_shape)
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = box.size
    surface.mesh = mesh
    surface.position = stage_shape.position
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("aaa68f")
    material.roughness = 0.9
    surface.material_override = material
    stage.add_child(surface)
    # A quiet inset boundary, without a wall: bodies can fall off every side.
    for side in range(4):
        var edge := MeshInstance3D.new()
        var strip := BoxMesh.new()
        strip.size = Vector3(9.3, 0.008, 0.045)
        edge.mesh = strip
        edge.position = Vector3(0, 0.005, -4.65).rotated(Vector3.UP, side * PI / 2.0)
        edge.rotation.y = side * PI / 2.0
        var ink := StandardMaterial3D.new()
        ink.albedo_color = Color("a59e86")
        edge.material_override = ink
        stage.add_child(edge)
    camera = Camera3D.new()
    camera.position = Vector3(10, 12.5, 14)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 14.5
    add_child(camera)
    camera.look_at(Vector3(0, 0.1, 0))
    camera.current = true
    var positions := [Vector3(0, 0.05, 1.6), Vector3(-1.55, 0.05, -0.65), Vector3(1.55, 0.05, -0.65)]
    var colors := [Color("42d9bf"), Color("f2a358"), Color("b296ee")]
    for index in range(3):
        var character := Jelly.new()
        character.name = "Player" if index == 0 else "Pusher%d" % index
        character.is_player = index == 0
        character.ai_index = index
        character.tint = colors[index]
        character.spawn_position = positions[index]
        character.position = positions[index]
        add_child(character)
        characters.append(character)
    for character in characters:
        character.peers = characters
    _hud()

func _bind_key(action: String, key: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action, event)

func _physics_process(_delta: float) -> void:
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var right := camera.global_basis.x
    right.y = 0
    var back := camera.global_basis.z
    back.y = 0
    characters[0].control_direction = (right.normalized() * input.x + back.normalized() * input.y).limit_length()
    if Input.is_action_just_pressed("reset"):
        for character in characters:
            character.reset_body()

func _hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var title := Label.new()
    title.text = "JELLY / SUMO"
    title.position = Vector2(30, 24)
    title.add_theme_font_size_override("font_size", 27)
    title.modulate = Color("f3eddb")
    canvas.add_child(title)
    var hint := Label.new()
    hint.text = "押し心地のプロトタイプ  •  ミント色がプレイヤー"
    hint.position = Vector2(32, 65)
    hint.add_theme_font_size_override("font_size", 16)
    hint.modulate = Color("b6c8cd")
    canvas.add_child(hint)
    var controls := Label.new()
    controls.text = "W A S D  移動     /     R  配置をリセット\n身体を押し付ける → 離れて、ぷるん。落下したら自動で戻ります。"
    controls.position = Vector2(32, 686)
    controls.add_theme_font_size_override("font_size", 17)
    controls.modulate = Color("f3eddb")
    canvas.add_child(controls)

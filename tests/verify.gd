extends SceneTree

var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
    print(("PASS: " if condition else "FAIL: ") + message)

func frames(count: int) -> void:
    for i in range(count):
        await physics_frame

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    await frames(120)
    check(game.characters.size() == 3, "Three characters spawned")
    var player = game.characters[0]
    Input.action_press("move_right")
    await frames(20)
    check(player.control_direction.length() > 0.9, "WASD action drives player")
    Input.action_release("move_right")
    game.set_physics_process(false)
    var target = game.characters[1]
    for body in game.characters:
        body.is_player = true
        body.control_direction = Vector3.ZERO
    player.spawn_position = Vector3(-1.4, 0.03, 0)
    target.spawn_position = Vector3(0.2, 0.03, 0)
    game.characters[2].spawn_position = Vector3(3, 0.03, -3)
    for body in game.characters:
        body.reset_body()
    await frames(60)
    var start_x: float = target.position.x
    player.control_direction = Vector3.RIGHT
    var peak := 0.0
    for i in range(90):
        await physics_frame
        peak = maxf(peak, player.compression)
    check(target.position.x > start_x + 0.4, "Body contact pushes the other character")
    check(peak > 0.12 and target.compression > 0.10, "Both bellies compress on contact")
    if DisplayServer.get_name() != "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("user://verification-preview.png")
    player.control_direction = Vector3.LEFT
    var lowest := 1.0
    for i in range(160):
        await physics_frame
        lowest = minf(lowest, player.compression)
    check(lowest < -0.005, "Release overshoots into a jelly spring wobble")
    player.control_direction = Vector3.ZERO
    await frames(140)
    check(absf(player.compression) < 0.025, "Belly returns to its rest shape")
    player.spawn_position = Vector3(5.8, 0.1, 0)
    player.reset_body()
    await frames(30)
    player.spawn_position = Vector3(0, 0.05, 2)
    var fell := false
    var returned := false
    for i in range(260):
        await physics_frame
        if player.position.y < -2.0:
            fell = true
        if fell and player.position.y > -0.1:
            returned = true
    check(fell and returned, "Open stage edge allows falling and automatic return")
    print("RESULT: ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)

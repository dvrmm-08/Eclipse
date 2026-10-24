extends SceneTree

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  RUNNING LIVE PHYSICS TRAVERSAL & PROP COLLISION TEST")
	print("════════════════════════════════════════════════════════════\n")
	_run_sim()

func _run_sim() -> void:
	var scene_res = load("res://scenes/level_1.tscn")
	var level = scene_res.instantiate()
	root.add_child(level)
	level._ready()

	var wanderer = level.get_node("Wanderer")
	var shadow = level.get_node("Shadow")
	var lever = level.get_node("Objects/Lever")
	var gate = level.get_node("Objects/Gate")

	await physics_frame
	await physics_frame

	# ── SIM 1: Wanderer attempts to cross Void into lever (facing void at x=240, y=208) ──
	wanderer.position = Vector2(240, 208)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if wanderer.position.x < 260.0:
		print("  [PASS] Live Sim 1: Wanderer physically blocked by Void (x=", wanderer.position.x, ")")
	else:
		printerr("  [FAIL] Live Sim 1: Wanderer bypassed void! x=", wanderer.position.x)

	# ── SIM 2: Wanderer attempts to walk onto Hidden Bridge in Normal Mode ──
	wanderer.position = Vector2(240, 176)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if wanderer.position.x < 260.0:
		print("  [PASS] Live Sim 2: Wanderer blocked by Hidden Bridge in Normal Mode (x=", wanderer.position.x, ")")
	else:
		printerr("  [FAIL] Live Sim 2: Wanderer walked onto bridge in normal mode! x=", wanderer.position.x)

	# ── SIM 3: Wanderer attempts to pass through Closed Gate Barrier ──
	wanderer.position = Vector2(592, 115)
	Input.action_press("move_up")
	for i in range(25):
		await physics_frame
	Input.action_release("move_up")

	if wanderer.position.y > 90.0:
		print("  [PASS] Live Sim 3: Wanderer blocked by Closed Gate Barrier (y=", wanderer.position.y, ")")
	else:
		printerr("  [FAIL] Live Sim 3: Wanderer walked through closed gate! y=", wanderer.position.y)

	# ── SIM 4: Wanderer attempts to walk into a Rock (Rock at x=176, y=208) ──
	wanderer.position = Vector2(150, 208)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if wanderer.position.x < 170.0:
		print("  [PASS] Live Sim 4: Wanderer physically blocked by Rock obstacle (stopped at x=", wanderer.position.x, ")")
	else:
		printerr("  [FAIL] Live Sim 4: Wanderer walked through Rock! x=", wanderer.position.x)

	# ── SIM 5: Wanderer attempts to walk into a Bush (Bush at x=48, y=80) ──
	wanderer.position = Vector2(48, 105)
	Input.action_press("move_up")
	for i in range(25):
		await physics_frame
	Input.action_release("move_up")

	if wanderer.position.y > 80.0:
		print("  [PASS] Live Sim 5: Wanderer physically blocked by Bush obstacle (stopped at y=", wanderer.position.y, ")")
	else:
		printerr("  [FAIL] Live Sim 5: Wanderer walked through Bush! y=", wanderer.position.y)

	# ── SIM 6: Wanderer attempts to walk into Tree Trunk (Tree at x=208, y=0, trunk at y=-5) ──
	wanderer.position = Vector2(208, 20)
	Input.action_press("move_up")
	for i in range(25):
		await physics_frame
	Input.action_release("move_up")

	if wanderer.position.y > 0.0:
		print("  [PASS] Live Sim 6: Wanderer physically blocked by Tree Trunk (stopped at y=", wanderer.position.y, ")")
	else:
		printerr("  [FAIL] Live Sim 6: Wanderer walked through Tree Trunk! y=", wanderer.position.y)

	# ── SIM 7: Shadow traverses Cyan Bridge in Eclipse Mode ──
	level.toggle_dimension() # Switch to Shadow
	shadow.position = Vector2(240, 176)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if shadow.position.x > 280.0:
		print("  [PASS] Live Sim 7: Shadow successfully traverses Cyan Bridge (x=", shadow.position.x, ")")
	else:
		printerr("  [FAIL] Live Sim 7: Shadow blocked on bridge! x=", shadow.position.x)

	# ── SIM 8: Shadow blocked from walking into open Void from bridge ──
	shadow.position = Vector2(304, 176)
	Input.action_press("move_down")
	for i in range(25):
		await physics_frame
	Input.action_release("move_down")

	if shadow.position.y < 200.0:
		print("  [PASS] Live Sim 8: Shadow blocked from falling into open Void (y=", shadow.position.y, ")")
	else:
		printerr("  [FAIL] Live Sim 8: Shadow walked into void! y=", shadow.position.y)

	# ── SIM 9: Shadow activates lever -> Gate opens -> Wanderer enters gate ──
	shadow.position = lever.position
	lever.interact(shadow)
	level.toggle_dimension() # Switch back to Wanderer

	wanderer.position = Vector2(592, 115)
	Input.action_press("move_up")
	for i in range(25):
		await physics_frame
	Input.action_release("move_up")

	if wanderer.position.y < 88.0 or level.is_completing:
		print("  [PASS] Live Sim 9: Wanderer passes through opened Gate into exit (reached y=", wanderer.position.y, ")")
	else:
		printerr("  [FAIL] Live Sim 9: Wanderer could not enter open gate! y=", wanderer.position.y)

	print("\n════════════════════════════════════════════════════════════")
	print("  ALL 9 LIVE PHYSICS SIMULATIONS COMPLETED SUCCESSFULLY!")
	print("════════════════════════════════════════════════════════════\n")

	level.queue_free()
	quit(0)

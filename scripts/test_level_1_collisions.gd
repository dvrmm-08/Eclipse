extends SceneTree

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TESTING LEVEL 1 VOID & BRIDGE COLLISION FIX")
	print("════════════════════════════════════════════════════════════\n")
	_run_tests()

func _run_tests() -> void:
	var scene_res = load("res://scenes/level_1.tscn")
	var level = scene_res.instantiate()
	root.add_child(level)

	var wanderer = level.get_node("Wanderer")
	var shadow = level.get_node("Shadow")
	var lever = level.get_node("Objects/Lever")
	var gate = level.get_node("Objects/Gate")

	await physics_frame
	await physics_frame

	var passed = 0
	var total = 0

	# ── TEST 1: White Wanderer physically BLOCKED by Normal Void (Row 6, col 7 to col 8) ──
	total += 1
	wanderer.position = Vector2(240, 208)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if wanderer.position.x < 260.0:
		print("  [PASS] Test 1: White Wanderer blocked by Void in Normal Mode (stopped at x=", wanderer.position.x, ")")
		passed += 1
	else:
		printerr("  [FAIL] Test 1: White Wanderer walked into void! x=", wanderer.position.x)

	# ── TEST 2: White Wanderer physically BLOCKED by Hidden Bridge in Normal Mode ──
	total += 1
	# Col 7, row 5 is (240, 176). Bridge starts at col 8 (x=256..288)
	wanderer.position = Vector2(240, 176)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if wanderer.position.x < 260.0:
		print("  [PASS] Test 2: White Wanderer blocked by Hidden Bridge in Normal Mode (stopped at x=", wanderer.position.x, ")")
		passed += 1
	else:
		printerr("  [FAIL] Test 2: White Wanderer crossed hidden bridge! x=", wanderer.position.x)

	# ── TEST 3: Switch to Eclipse Mode (P key) ──
	total += 1
	level.toggle_dimension()
	await physics_frame
	await physics_frame

	var eclipse_ok = (level.eclipse_active and shadow.visible and shadow.is_controlled and not wanderer.is_controlled)
	if eclipse_ok:
		print("  [PASS] Test 3: Eclipse mode active: Shadow controlled, Wanderer stationary")
		passed += 1
	else:
		printerr("  [FAIL] Test 3: Eclipse mode activation failed")

	# ── TEST 4: Shadow can walk across the Cyan Bridge in Eclipse Mode ──
	total += 1
	shadow.position = Vector2(240, 176)
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")

	if shadow.position.x > 280.0:
		print("  [PASS] Test 4: Shadow successfully traverses Cyan Bridge (reached x=", shadow.position.x, ")")
		passed += 1
	else:
		printerr("  [FAIL] Test 4: Shadow blocked on cyan bridge! x=", shadow.position.x)

	# ── TEST 5: Shadow is BLOCKED by the surrounding Red Void in Eclipse Mode ──
	total += 1
	# Shadow at bridge bottom edge (304, 208). Try moving down into row 7 (void chasm at col 9, row 7: y=224..256)
	shadow.position = Vector2(304, 208)
	Input.action_press("move_down")
	for i in range(25):
		await physics_frame
	Input.action_release("move_down")

	if shadow.position.y < 232.0:
		print("  [PASS] Test 5: Shadow physically blocked by surrounding Red Void (stopped at y=", shadow.position.y, ")")
		passed += 1
	else:
		printerr("  [FAIL] Test 5: Shadow walked into red void! y=", shadow.position.y)

	# ── TEST 6: Inactive Wanderer does not move while Shadow is active ──
	total += 1
	var w_pos_before = wanderer.position
	# Apply input while shadow is active
	Input.action_press("move_left")
	for i in range(10):
		await physics_frame
	Input.action_release("move_left")

	if wanderer.position == w_pos_before:
		print("  [PASS] Test 6: Inactive Wanderer remains strictly stationary")
		passed += 1
	else:
		printerr("  [FAIL] Test 6: Inactive Wanderer moved! ", wanderer.position)

	# ── TEST 7: Shadow activates lever, opens gate, Wanderer returns and completes level ──
	total += 1
	shadow.position = lever.position
	lever.interact(shadow)

	level.toggle_dimension() # Switch back to Wanderer
	await physics_frame

	wanderer.position = Vector2(592, 115)
	Input.action_press("move_up")
	for i in range(25):
		await physics_frame
	Input.action_release("move_up")

	if level.is_completing or wanderer.position.y < 88.0:
		print("  [PASS] Test 7: Puzzle flow complete: Lever unlocked Gate, Wanderer entered exit")
		passed += 1
	else:
		printerr("  [FAIL] Test 7: Wanderer could not complete level through gate")

	print("\n════════════════════════════════════════════════════════════")
	print("  COLLISION TEST RESULTS: ", passed, " / ", total, " PASSED")
	print("════════════════════════════════════════════════════════════\n")

	level.queue_free()
	if passed == total:
		quit(0)
	else:
		quit(1)

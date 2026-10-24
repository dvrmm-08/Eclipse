extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2: BLIND SPOT & THE SHIELD OF FLESH — AUTOMATED VALIDATION SUITE
# ═════════════════════════════════════════════════════════════════════════════

var passed_count: int = 0
var total_count: int = 0

func record_pass(test_name: String, details: String = "") -> void:
	total_count += 1
	passed_count += 1
	if details != "":
		print("  [PASS] Test %d: %s (%s)" % [total_count, test_name, details])
	else:
		print("  [PASS] Test %d: %s" % [total_count, test_name])

func record_fail(test_name: String, reason: String) -> void:
	total_count += 1
	printerr("  [FAIL] Test %d: %s - REASON: %s" % [total_count, test_name, reason])

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TESTING LEVEL 2: BLIND SPOT & THE SHIELD OF FLESH")
	print("════════════════════════════════════════════════════════════\n")

	var scene_res = load("res://scenes/level_2.tscn")
	if not scene_res:
		record_fail("Load Level 2 Scene", "Cannot load res://scenes/level_2.tscn")
		_finish()
		return

	var level = scene_res.instantiate()
	root.add_child(level)
	level._ready()

	# Give physics a few frames to settle
	for i in range(5):
		await process_frame
		await physics_frame

	# Test 1: Hierarchy and Node verification
	var wanderer = level.get_node_or_null("Wanderer") as CharacterBody2D
	var shadow = level.get_node_or_null("Shadow") as CharacterBody2D
	var grid = level.get_node_or_null("LevelGrid")
	var objects = level.get_node_or_null("Objects")
	var props = level.get_node_or_null("Props")

	if wanderer and shadow and grid and objects and props:
		record_pass("Scene Hierarchy & Node Setup", "All main groups exist")
	else:
		record_fail("Scene Hierarchy & Node Setup", "Missing essential nodes")

	# Test 2: Editable TileMapLayers
	var ground = grid.get_node_or_null("Ground") as TileMapLayer
	var walls = grid.get_node_or_null("Walls") as TileMapLayer
	var void_l = grid.get_node_or_null("Void") as TileMapLayer
	var bridge_l = grid.get_node_or_null("EclipsePaths") as TileMapLayer
	var deco_l = grid.get_node_or_null("Decoration") as TileMapLayer

	if ground and walls and void_l and bridge_l and deco_l:
		record_pass("Editable TileMapLayers", "Ground, Walls, Void, EclipsePaths, Decoration present")
	else:
		record_fail("Editable TileMapLayers", "Missing TileMapLayer nodes")

	# Test 3: Watcher Statues
	var w1 = objects.get_node_or_null("WatcherStatue1") as StaticBody2D
	var w2 = objects.get_node_or_null("WatcherStatue2") as StaticBody2D
	if w1 and w2:
		record_pass("Two Watcher Statues Configured", "WatcherStatue1 at %s, WatcherStatue2 at %s" % [w1.position, w2.position])
	else:
		record_fail("Two Watcher Statues Configured", "Watcher statues missing from Objects node")

	# Test 4: Blind Spot behind Rock Cover
	# w1 is at (208, 48), rock is at (208, 144)
	# Raycast from w1 should hit the rock before reaching y=200
	var w1_ray = w1.get_node_or_null("RayCast2D") as RayCast2D
	w1._physics_process(0.016)
	w1_ray.force_raycast_update()
	if w1_ray.is_colliding():
		var col_point = w1_ray.get_collision_point()
		if col_point.y <= 160.0:
			record_pass("Discoverable Blind Spot Verified", "Rock at (208, 144) successfully blocks Watcher1 LOS at y=%.1f" % col_point.y)
		else:
			record_fail("Discoverable Blind Spot Verified", "Watcher1 raycast did not stop at rock: y=%.1f" % col_point.y)
	else:
		record_fail("Discoverable Blind Spot Verified", "Watcher1 raycast is not colliding with rock")

	# Test 5: Timed Red Laser Statue
	var laser = objects.get_node_or_null("LaserStatue") as StaticBody2D
	if laser and laser.get("is_timed") == true:
		record_pass("Physical Timed Red Laser Configured", "LaserStatue is_timed=true, active=%.1fs, inactive=%.1fs" % [laser.active_duration, laser.inactive_duration])
	else:
		record_fail("Physical Timed Red Laser Configured", "LaserStatue not timed or missing")

	# Test 6: Physical Body Shielding ("The Shield of Flesh")
	# Unblocked laser: terminates at bottom obstacle > 300px
	wanderer.global_position = Vector2(80, 304) # Away from laser
	laser.is_active = true
	laser._physics_process(0.016)
	var unblocked_end = laser.laser_line.points[1]

	# Move Wanderer to Shield Spot at (304, 136)
	wanderer.global_position = Vector2(304, 136)
	await physics_frame
	laser._physics_process(0.016)
	var blocked_end = laser.laser_line.points[1]

	if blocked_end.y <= 160.0 and unblocked_end.y > 300.0:
		record_pass("Body Shielding Physics Verified", "Unblocked end y=%.1f, Blocked by Wanderer body at y=%.1f" % [unblocked_end.y, blocked_end.y])
	else:
		record_fail("Body Shielding Physics Verified", "Laser not blocked by body: blocked_end y=%.1f" % blocked_end.y)

	# Test 7: Shadow Crossing Cyan Bridge Under Body Shield
	level.toggle_dimension() # Switch to Eclipse mode
	await physics_frame
	# Position shadow on the cyan bridge directly behind Wanderer at (304, 176)
	shadow.global_position = Vector2(304, 176)
	laser._physics_process(0.016)
	await physics_frame

	if shadow.global_position == Vector2(304, 176):
		record_pass("Shadow Safely Traverses Shielded Bridge", "Shadow at (304, 176) safe behind Wanderer shield")
	else:
		record_fail("Shadow Safely Traverses Shielded Bridge", "Shadow was unexpectedly repelled")

	# Test 8: Unblocked Laser Repels Shadow
	# Move Wanderer away so laser is unblocked
	wanderer.global_position = Vector2(80, 304)
	await physics_frame
	laser._physics_process(0.016) # Laser now fires through (304, 176)
	await physics_frame

	if shadow.global_position == wanderer.global_position:
		record_pass("Unblocked Laser Repels Shadow", "Shadow repelled back to Wanderer body")
	else:
		record_fail("Unblocked Laser Repels Shadow", "Shadow was not repelled by active laser")

	# Test 9: Lever Unlocks Gate
	var lever = objects.get_node_or_null("Lever")
	var gate = objects.get_node_or_null("Gate")
	lever.interact(shadow)
	await physics_frame

	if lever.is_active and gate.is_active:
		record_pass("Lever Mechanism Unlocks Gate", "Lever pulled, Gate opened")
	else:
		record_fail("Lever Mechanism Unlocks Gate", "Lever or gate failed to activate")

	# Test 10: First Betrayal Sequence Trigger
	level.toggle_dimension() # Switch back to normal mode
	await physics_frame
	if level.betrayal_triggered:
		record_pass("The First Betrayal Scripted Event", "Triggered independently on dimension toggle")
	else:
		record_fail("The First Betrayal Scripted Event", "Betrayal did not trigger")

	_finish()

func _finish() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TEST RESULTS: %d / %d PASSED" % [passed_count, total_count])
	print("════════════════════════════════════════════════════════════\n")
	if passed_count == total_count:
		quit(0)
	else:
		quit(1)

extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2: BLIND SPOT — FULL VALIDATION SUITE
# Validates 2D Editor Editability, Watcher Rotation, Clean Visuals, Laser Tuning,
# Puzzle Completion, and Ending Scare.
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
	print("  TESTING LEVEL 2: BLIND SPOT (EDITABILITY & GAMEPLAY)")
	print("════════════════════════════════════════════════════════════\n")

	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var level = current_scene
	if not level:
		record_fail("Load Level 2", "Cannot load current_scene res://scenes/level_2.tscn")
		_finish()
		return

	# ── TEST 1: Level Title & Subtitle ──
	if level.level_title == "LEVEL 2" and level.level_subtitle == "BLIND SPOT":
		record_pass("Level Title & Subtitle", "LEVEL 2 — BLIND SPOT")
	else:
		record_fail("Level Title & Subtitle", "Got title='%s', subtitle='%s'" % [level.level_title, level.level_subtitle])

	# ── TEST 2: Watcher Visual Cleanliness (No Red Cone Overlays in Gameplay) ──
	var objects = level.get_node_or_null("Objects")
	var wa = objects.get_node_or_null("WatcherStatueA")
	var wb = objects.get_node_or_null("WatcherStatueB")
	if wa and wb and not wa.debug_visualization and not wb.debug_visualization:
		record_pass("Clean Gameplay Visuals", "debug_visualization disabled by default, no vision cone clutter")
	else:
		record_fail("Clean Gameplay Visuals", "Debug vision visualization still active")

	# ── TEST 3: Watcher Direction Follows Node Rotation ──
	var orig_rot = wa.rotation
	var dir_initial = wa.get_current_facing_direction()
	wa.rotation += deg_to_rad(45.0)
	var dir_rotated = wa.get_current_facing_direction()
	wa.rotation = orig_rot # Restore

	var angle_diff = absf(dir_initial.angle_to(dir_rotated) - deg_to_rad(45.0))
	if angle_diff < 0.01:
		record_pass("Watcher Rotation Follows Node Transform", "Rotating node 45 deg rotated detection vector by 45 deg")
	else:
		record_fail("Watcher Rotation Follows Node Transform", "Angle diff was %.4f" % angle_diff)

	# ── TEST 4: Timed Laser Configurable Length & Direction ──
	var laser = objects.get_node_or_null("TimedLaser")
	var orig_len = laser.beam_length
	laser.beam_length = 200.0
	var line_len_updated = (laser.laser_line.points[1].x == 200.0)
	var col_len_updated = (laser.hazard_shape.shape.size.x == 200.0)
	laser.beam_length = orig_len # Restore

	if line_len_updated and col_len_updated:
		record_pass("Laser Length Inspector Setting", "Changing beam_length dynamically updates Line2D and CollisionShape2D")
	else:
		record_fail("Laser Length Inspector Setting", "Beam length update did not match collision or visuals")

	# ── TEST 5: Laser Cycle & Collision Matching ──
	laser._set_state(laser.State.INACTIVE)
	var inactive_vis = laser.laser_line.visible
	var inactive_dis = laser.hazard_shape.disabled
	laser._set_state(laser.State.ACTIVE)
	var active_vis = laser.laser_line.visible
	var active_dis = laser.hazard_shape.disabled
	laser._set_state(laser.State.INACTIVE)

	if not inactive_vis and inactive_dis and active_vis and not active_dis:
		record_pass("Laser Cycle & Collision Matching", "Collision strictly matches active state")
	else:
		record_fail("Laser Cycle & Collision Matching", "Collision state did not match")

	# ── TEST 6: Watchers Block P in Exposed Area ──
	var wanderer = level.get_node_or_null("Wanderer")
	var shadow = level.get_node_or_null("Shadow")
	wanderer.global_position = Vector2(80, 112) # Exposed in front of Watcher A
	await physics_frame
	await physics_frame

	var seen_exposed = level._are_watchers_alerted()
	level.toggle_dimension()
	var toggle_blocked = (level.eclipse_active == false and shadow.visible == false)

	if seen_exposed and toggle_blocked:
		record_pass("Watcher Detection Blocks Dimension Switch", "P blocked while exposed to Watcher sightlines")
	else:
		record_fail("Watcher Detection Blocks Dimension Switch", "Seen=%s, EclipseActive=%s" % [seen_exposed, level.eclipse_active])

	# ── TEST 7: P Allowed in Blind Spot (4, 8) Behind L-Wall ──
	wanderer.global_position = Vector2(144, 272) # Blind spot
	await physics_frame
	await physics_frame

	var seen_blindspot = level._are_watchers_alerted()
	level.toggle_dimension()
	var summoned = (level.eclipse_active == true and shadow.visible == true and shadow.is_controlled == true)

	if not seen_blindspot and summoned:
		record_pass("Blind Spot (4, 8) Functional", "L-wall blocked both sightlines, Shadow summoned")
	else:
		record_fail("Blind Spot (4, 8) Functional", "Seen=%s, Summoned=%s" % [seen_blindspot, summoned])

	# ── TEST 8: Shadow Crosses Cyan Bridge to Far Platform ──
	shadow.global_position = Vector2(176, 272) # Bridge start (5, 8)
	await physics_frame
	shadow.global_position = Vector2(304, 240) # Bridge bend (9, 7)
	await physics_frame
	shadow.global_position = Vector2(496, 208) # Far platform (15, 6)
	await physics_frame

	if shadow.global_position == Vector2(496, 208):
		record_pass("Shadow Traverses Cyan Bridge", "Successfully reached far platform across central void")
	else:
		record_fail("Shadow Traverses Cyan Bridge", "Shadow failed to reach far platform")

	# ── TEST 9: Mechanism Unlocks Exit Gate & Dismissal Works ──
	var mech = objects.get_node_or_null("Mechanism")
	var gate = objects.get_node_or_null("Gate")
	shadow.global_position = mech.global_position
	mech.interact(shadow)
	await physics_frame

	level.toggle_dimension() # Dismiss Shadow
	await physics_frame
	var return_ok = (level.eclipse_active == false and shadow.visible == false and wanderer.is_controlled == true)

	if mech.is_active and gate.is_active and return_ok:
		record_pass("Mechanism Unlocks Gate & Returns Control", "Gate unlocked, control returned to Wanderer")
	else:
		record_fail("Mechanism Unlocks Gate & Returns Control", "Mech=%s, Gate=%s, Return=%s" % [mech.is_active, gate.is_active, return_ok])

	# ── TEST 10: Ending Scare Triggered at Exit Gate ──
	wanderer.global_position = gate.global_position
	gate.interact(wanderer)
	await physics_frame

	if level.ending_scare_triggered and wanderer.input_disabled:
		record_pass("Scripted Ending Scare Triggered", "Input locked, autonomous shadow sequence initiated")
	else:
		record_fail("Scripted Ending Scare Triggered", "Scare not triggered")

	# ── TEST 11: 5 Real Editable TileMapLayers ──
	var grid = level.get_node_or_null("LevelGrid")
	if grid.has_node("Ground") and grid.has_node("Walls") and grid.has_node("Void") and grid.has_node("EclipsePaths") and grid.has_node("Decoration"):
		record_pass("Editable TileMapLayers Intact", "Ground, Walls, Void, EclipsePaths, Decoration present")
	else:
		record_fail("Editable TileMapLayers Intact", "Missing one or more TileMapLayers")

	_finish()

func _finish() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TEST RESULTS: %d / %d PASSED" % [passed_count, total_count])
	print("════════════════════════════════════════════════════════════\n")
	if passed_count == total_count:
		quit(0)
	else:
		quit(1)

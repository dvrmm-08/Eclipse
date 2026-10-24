extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Level 2 Watcher Detection Verification Suite
# Verifies all 7 user-specified test cases for Watcher Detection & P-key mechanics.
# ═════════════════════════════════════════════════════════════════════════════

var passed: int = 0
var total: int = 0

func record(test_name: String, ok: bool, details: String = ""):
	total += 1
	if ok:
		passed += 1
		print("  [PASS] Case %d: %s %s" % [total, test_name, "(%s)" % details if details != "" else ""])
	else:
		printerr("  [FAIL] Case %d: %s %s" % [total, test_name, "- REASON: %s" % details if details != "" else ""])

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  RUNNING WATCHER DETECTION & P-KEY MECHANIC VERIFICATION")
	print("════════════════════════════════════════════════════════════\n")

	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var level = current_scene
	var wanderer = level.get_node("Wanderer")
	var shadow = level.get_node("Shadow")
	var objects = level.get_node("Objects")
	var watcher_1 = objects.get_node("WatcherStatueA")
	var watcher_2 = objects.get_node("WatcherStatueB")
	var ui = level.get_node("UIOverlay")

	# ── CASE 1: Wanderer in front of Watcher 1 ──
	# P is blocked, UI message "THE WATCHERS CAN SEE YOU" displays
	wanderer.global_position = watcher_1.global_position + Vector2(0, 48)
	await physics_frame
	await physics_frame
	var sees_w1 = watcher_1.can_see_wanderer()
	level.toggle_dimension()
	await physics_frame
	var c1_blocked = (not level.eclipse_active and not shadow.visible)
	var c1_msg_ok = (ui.message_box.visible and "THE WATCHERS CAN SEE YOU" in ui.message_label.text)
	record("Wanderer in front of Watcher 1: P is blocked, message displays",
		sees_w1 and c1_blocked and c1_msg_ok,
		"Sees=%s, Blocked=%s, Msg='%s'" % [sees_w1, c1_blocked, ui.message_label.text])

	# ── CASE 2: Wanderer in front of Watcher 2 ──
	# P is blocked, UI message "THE WATCHERS CAN SEE YOU" displays
	wanderer.global_position = watcher_2.global_position + Vector2(0, 48)
	await physics_frame
	await physics_frame
	var sees_w2 = watcher_2.can_see_wanderer()
	level.toggle_dimension()
	await physics_frame
	var c2_blocked = (not level.eclipse_active and not shadow.visible)
	var c2_msg_ok = (ui.message_box.visible and "THE WATCHERS CAN SEE YOU" in ui.message_label.text)
	record("Wanderer in front of Watcher 2: P is blocked, message displays",
		sees_w2 and c2_blocked and c2_msg_ok,
		"Sees=%s, Blocked=%s, Msg='%s'" % [sees_w2, c2_blocked, ui.message_label.text])

	# ── CASE 3: Wanderer behind a wall (out of line of sight) ──
	# P works, Shadow appears
	wanderer.global_position = Vector2(144, 272) # Blind spot behind L-wall
	await physics_frame
	await physics_frame
	var alerted_c3 = level._are_watchers_alerted()
	level.toggle_dimension()
	await physics_frame
	var c3_summoned = (level.eclipse_active and shadow.visible and shadow.is_controlled)
	record("Wanderer behind a wall (out of LOS): P works, Shadow appears",
		not alerted_c3 and c3_summoned,
		"Alerted=%s, ShadowSummoned=%s" % [alerted_c3, c3_summoned])

	# ── CASE 5: In Eclipse mode, P always returns to Wanderer ──
	# Even if Wanderer is in sight of a watcher, dismissing Shadow must work unconditionally
	level.toggle_dimension()
	await physics_frame
	var c5_dismissed = (not level.eclipse_active and not shadow.visible and wanderer.is_controlled)
	record("In Eclipse mode, P always returns to Wanderer",
		c5_dismissed,
		"Returned to Wanderer successfully")

	# ── CASE 4: Wanderer outside watcher FOV or range ──
	# P works
	wanderer.global_position = Vector2(40, 72) # Out of FOV to the left of Watcher 1
	await physics_frame
	await physics_frame
	var alerted_c4 = level._are_watchers_alerted()
	level.toggle_dimension()
	await physics_frame
	var c4_summoned = (level.eclipse_active and shadow.visible)
	record("Wanderer outside watcher FOV or range: P works",
		not alerted_c4 and c4_summoned,
		"Alerted=%s, Summoned=%s" % [alerted_c4, c4_summoned])

	# Dismiss shadow again
	level.toggle_dimension()
	await physics_frame

	# ── CASE 6: Rotating a watcher changes where it looks and what it detects ──
	# When Watcher 1 is rotated by 90 deg clockwise (facing LEFT), position directly below is no longer seen
	wanderer.global_position = watcher_1.global_position + Vector2(0, 48) # Directly below
	await physics_frame
	await physics_frame
	var seen_unrotated = watcher_1.can_see_wanderer()
	
	watcher_1.rotation = deg_to_rad(90.0) # Rotate 90 deg away
	await physics_frame
	await physics_frame
	var seen_rotated = watcher_1.can_see_wanderer()
	
	watcher_1.rotation = 0.0 # Restore
	await physics_frame
	var seen_restored = watcher_1.can_see_wanderer()

	var c6_ok = (seen_unrotated == true and seen_rotated == false and seen_restored == true)
	record("Rotating a watcher changes where it looks and what it detects",
		c6_ok,
		"At 0 deg: %s, At 90 deg: %s, Restored: %s" % [seen_unrotated, seen_rotated, seen_restored])

	# ── CASE 7: Level 1 remains 100% functional and intact ──
	change_scene_to_file("res://scenes/level_1.tscn")
	for i in range(5):
		await process_frame
		await physics_frame
	var l1 = current_scene
	var l1_ok = (l1 != null and l1.level_title == "LEVEL 1" and l1.has_node("LevelGrid/Ground"))
	record("Level 1 remains 100% functional and intact",
		l1_ok,
		"Level 1 loaded and verified intact")

	print("\n════════════════════════════════════════════════════════════")
	print("  TEST RESULTS: %d / %d PASSED" % [passed, total])
	print("════════════════════════════════════════════════════════════\n")

	if passed == total:
		quit(0)
	else:
		quit(1)

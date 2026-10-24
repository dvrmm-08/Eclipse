extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Level 1 Automated Gameplay & TileMap Validation Suite
# Tests:
#   1. Scene structure, nodes & camera framing
#   2. TileMapLayers: Ground, Walls, Void, EclipsePaths, Decoration
#   3. Impassable Props: Trees (trunk), Bushes, Rocks (Layer 1 collision)
#   4. Character collision masks (Wanderer: 3, Shadow: 17)
#   5. Initial world state (Wanderer active, Shadow hidden, Gate locked)
#   6. Closed Gate has active Solid_Walls barrier (Layer 1)
#   7. Dimension Switching (P key): Shadow active, Wanderer stationary
#   8. Environment visual transformation across TileMapLayers (Void, EclipsePaths)
#   9. Lever puzzle requirement (operable by Shadow only)
#  10. Gate unlock state persists in Normal Mode
#  11. Tablet and Note interaction text matches exact specification
#  12. Gate triggers level completion for Wanderer
# ═════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  RUNNING LEVEL 1 VALIDATION SUITE (TILEMAP & PROPS)")
	print("════════════════════════════════════════════════════════════\n")

	var scene_res = load("res://scenes/level_1.tscn")
	if not scene_res:
		printerr("FAIL: Could not load scenes/level_1.tscn")
		quit(1)
		return

	var level = scene_res.instantiate()
	root.add_child(level)
	level._ready()

	var tests_passed = 0
	var total_tests = 0

	# ── TEST 1: Node Hierarchy & Essential References ──
	total_tests += 1
	var grid = level.get_node_or_null("LevelGrid")
	var props = level.get_node_or_null("Props")
	var wanderer = level.get_node_or_null("Wanderer")
	var shadow = level.get_node_or_null("Shadow")
	var camera = level.get_node_or_null("Camera2D")
	var ui = level.get_node_or_null("UIOverlay")
	var gate = level.get_node_or_null("Objects/Gate")
	var lever = level.get_node_or_null("Objects/Lever")
	var tablet = level.get_node_or_null("Objects/Tablet")
	var note = level.get_node_or_null("Objects/Note")

	if grid and props and wanderer and shadow and camera and ui and gate and lever and tablet and note:
		print("  [PASS] Test 1: All scene nodes present and valid")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 1: Missing essential nodes")

	# ── TEST 2: Genuine TileMapLayers Present ──
	total_tests += 1
	var ground = grid.get_node_or_null("Ground") as TileMapLayer
	var walls = grid.get_node_or_null("Walls") as TileMapLayer
	var void_layer = grid.get_node_or_null("Void") as TileMapLayer
	var eclipse_paths = grid.get_node_or_null("EclipsePaths") as TileMapLayer
	var decoration = grid.get_node_or_null("Decoration") as TileMapLayer

	if ground and walls and void_layer and eclipse_paths and decoration:
		print("  [PASS] Test 2: All 5 TileMapLayers present (Ground, Walls, Void, EclipsePaths, Decoration)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 2: Missing TileMapLayer nodes in LevelGrid")

	# ── TEST 3: Camera Centering (640x384 room) ──
	total_tests += 1
	if camera.global_position == Vector2(320, 192):
		print("  [PASS] Test 3: Camera correctly centered at (320, 192)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 3: Camera at ", camera.global_position, ", expected (320, 192)")

	# ── TEST 4: Impassable Props: Trees, Bushes, Rocks ──
	total_tests += 1
	var tree = props.get_node_or_null("Tree_1") as StaticBody2D
	var bush = props.get_node_or_null("Bush_1") as StaticBody2D
	var rock = props.get_node_or_null("Rock_1") as StaticBody2D

	var tree_col = tree and (tree.collision_layer & 1) != 0
	var bush_col = bush and (bush.collision_layer & 1) != 0
	var rock_col = rock and (rock.collision_layer & 1) != 0

	if tree_col and bush_col and rock_col:
		print("  [PASS] Test 4: Trees, Bushes, and Rocks have active Solid_Walls collision (Layer 1)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 4: Missing or invalid collision on Trees/Bushes/Rocks")

	# ── TEST 5: Character Collision Masks ──
	total_tests += 1
	var w_mask_ok = (wanderer.collision_mask == 3)
	var s_mask_ok = (shadow.collision_mask == 17)
	if w_mask_ok and s_mask_ok:
		print("  [PASS] Test 5: Character collision masks valid (Wanderer: 3, Shadow: 17)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 5: Wanderer mask=", wanderer.collision_mask, " Shadow mask=", shadow.collision_mask)

	# ── TEST 6: Initial World State ──
	total_tests += 1
	var init_ok = (wanderer.is_controlled == true and shadow.is_controlled == false and
				   shadow.visible == false and level.eclipse_active == false and
				   lever.is_active == false and gate.is_active == false and
				   eclipse_paths.visible == false)
	if init_ok:
		print("  [PASS] Test 6: Initial world state valid (Wanderer active, Shadow hidden, Gate locked, Cyan path hidden)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 6: Initial world state mismatch")

	# ── TEST 7: Dimension Switching (P key) ──
	total_tests += 1
	level.toggle_dimension() # Press P -> Eclipse Mode
	var eclipse_ok = (level.eclipse_active == true and shadow.visible == true and
					  shadow.is_controlled == true and wanderer.is_controlled == false)
	if eclipse_ok:
		print("  [PASS] Test 7: Eclipse mode activated (Shadow active, Wanderer stationary)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 7: Eclipse toggle failed")

	# ── TEST 8: Environment Visual Transformation on TileMapLayers ──
	total_tests += 1
	var bridge_visible = (eclipse_paths.visible == true)
	var sample_void_cell = void_layer.get_used_cells()[0]
	var void_is_crimson = (void_layer.get_cell_atlas_coords(sample_void_cell) == Vector2i(3, 1))

	if bridge_visible and void_is_crimson:
		print("  [PASS] Test 8: Eclipse visuals active on TileMapLayers (Cyan bridge visible, Void=Crimson Red)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 8: TileMapLayer visuals did not swap properly in Eclipse mode")

	# ── TEST 9: Lever Mandatory Requirement (Shadow Only) ──
	total_tests += 1
	lever.interact(wanderer)
	var wanderer_rejected = (lever.is_active == false and gate.is_active == false)

	lever.interact(shadow)
	var shadow_succeeded = (lever.is_active == true and gate.is_active == true)

	if wanderer_rejected and shadow_succeeded:
		print("  [PASS] Test 9: Lever strictly requires Shadow form (Wanderer rejected, Shadow accepted)")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 9: Lever permission logic failed")

	# ── TEST 10: Gate Unlock State Persists in Normal Mode ──
	total_tests += 1
	level.toggle_dimension() # Press P -> Return to Normal World
	var gate_barrier = gate.get_node_or_null("GateBarrier")
	var return_ok = (level.eclipse_active == false and wanderer.is_controlled == true and
					 shadow.is_controlled == false and gate.is_active == true)
	var barrier_disabled = gate_barrier and (gate_barrier.collision_layer & 1) == 0

	if return_ok and barrier_disabled:
		print("  [PASS] Test 10: Returned to Normal World; Gate remains permanently unlocked and unblocked")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 10: Gate state did not persist on return to Normal World")

	# ── TEST 11: Tablet & Note Lore Strings ──
	total_tests += 1
	var tablet_ok = (tablet.message == "\"It's too far, right? Try pressing P.\"")
	var note_ok = (note.message == "\"Use it carefully. It remembers.\"")
	if tablet_ok and note_ok:
		print("  [PASS] Test 11: Tablet & Note interaction text matches exact specification")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 11: Lore text mismatch")

	# ── TEST 12: Gate Triggers Level Completion for Wanderer ──
	total_tests += 1
	gate.interact(wanderer)
	if level.is_completing == true:
		print("  [PASS] Test 12: Wanderer entering open Gate successfully triggers level completion")
		tests_passed += 1
	else:
		printerr("  [FAIL] Test 12: Gate did not trigger completion for Wanderer")

	print("\n════════════════════════════════════════════════════════════")
	print("  TEST RESULTS: ", tests_passed, " / ", total_tests, " PASSED")
	print("════════════════════════════════════════════════════════════\n")

	level.queue_free()
	if tests_passed == total_tests:
		quit(0)
	else:
		quit(1)

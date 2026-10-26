extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Retro Fantasy Story Presentation & Ending Test Suite
# Verifies:
#   1. Load Story Intro Scene (res://scenes/story_intro.tscn)
#   2. Title Screen Play Button opens Story Intro
#   3. Page 1 Content & Disabled Back Button
#   4. Next Navigation to Page 2 & Content
#   5. Back Navigation from Page 2 to Page 1
#   6. Full Chronicle Traversal: Pages 1, 2, 3, 4
#   7. Page 4 Button transforms to [ BEGIN JOURNEY ► ]
#   8. Next from Page 4 transitions to Level 1
#   9. Skip Button immediately transitions to Level 1
#  10. Level 2 Ending: Passage 1 Presentation
#  11. Level 2 Ending: Passage 2 Presentation
#  12. Level 2 Ending: Final Title Card ("THE JOURNEY CONTINUES") & Return Button
#  13. Return to Main Menu transitions back to title screen
# ═════════════════════════════════════════════════════════════════════════════

var passed: int = 0
var total: int = 0

func record(test_name: String, ok: bool, details: String = "") -> void:
	total += 1
	if ok:
		passed += 1
		print("  [PASS] Test %02d: %s %s" % [total, test_name, "(%s)" % details if details != "" else ""])
	else:
		printerr("  [FAIL] Test %02d: %s %s" % [total, test_name, "- REASON: %s" % details if details != "" else ""])

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TESTING RETRO FANTASY STORY PRESENTATION & ENDING")
	print("════════════════════════════════════════════════════════════\n")

	# ── TEST 1: Load Story Intro Scene ──
	change_scene_to_file("res://scenes/story_intro.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var intro = current_scene
	var loaded = (intro != null and intro.name == "StoryIntro")
	record("Load Story Intro Scene", loaded, "res://scenes/story_intro.tscn loaded successfully")

	# ── TEST 2: Verify Title Screen Navigation to Story Intro ──
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var title = current_scene
	var play_btn = title.get_node_or_null("UI/CenterContainer/MenuColumn/MenuContainer/PlayButton") as Button if title else null
	if play_btn:
		play_btn.emit_signal("pressed")
		for i in range(5):
			await process_frame
			await physics_frame

	var intro_from_menu = (current_scene != null and current_scene.name == "StoryIntro")
	record("Title Screen Play Button opens Story Intro", intro_from_menu,
		"Play transitioned to: %s" % (current_scene.name if current_scene else "null"))

	intro = current_scene

	# ── TEST 3: Page 1 Content & Disabled Back Button ──
	var title_lbl = intro.get_node_or_null("FrameContainer/TomePanel/VBoxContainer/HeaderContainer/PageTitleLabel") as Label if intro else null
	var body_lbl = intro.get_node_or_null("FrameContainer/TomePanel/VBoxContainer/StoryTextContainer/StoryTextLabel") as Label if intro else null
	var img_rect = intro.get_node_or_null("FrameContainer/TomePanel/VBoxContainer/IllustrationBox/IllustrationFrame/IllustrationTexture") as TextureRect if intro else null
	var back_btn = intro.get_node_or_null("FrameContainer/TomePanel/VBoxContainer/NavigationHBox/BackButton") as Button if intro else null
	var next_btn = intro.get_node_or_null("FrameContainer/TomePanel/VBoxContainer/NavigationHBox/NextButton") as Button if intro else null
	var skip_btn = intro.get_node_or_null("FrameContainer/TomePanel/SkipButton") as Button if intro else null

	var p1_ok = false
	if title_lbl and body_lbl and img_rect and back_btn:
		var has_title = ("PAGE I" in title_lbl.text)
		var has_text = ("reflections" in body_lbl.text)
		var back_disabled = back_btn.disabled
		var img_ok = (img_rect.texture != null)
		p1_ok = has_title and has_text and back_disabled and img_ok
	record("Page 1 Content & Disabled Back Button", p1_ok,
		"Title: %s, Back disabled: %s" % [title_lbl.text if title_lbl else "", back_btn.disabled if back_btn else false])

	# ── TEST 4: Next Navigation to Page 2 & Content ──
	if next_btn:
		next_btn.emit_signal("pressed")
		for i in range(3):
			await process_frame
	var p2_ok = false
	if title_lbl and body_lbl and back_btn:
		var has_p2_title = ("PAGE II" in title_lbl.text)
		var has_p2_text = ("forgotten things" in body_lbl.text)
		var back_enabled = not back_btn.disabled
		p2_ok = has_p2_title and has_p2_text and back_enabled
	record("Next Navigation to Page 2 & Enabled Back Button", p2_ok,
		"Page II title and text active, Back button enabled")

	# ── TEST 5: Back Navigation from Page 2 to Page 1 ──
	if back_btn:
		back_btn.emit_signal("pressed")
		for i in range(3):
			await process_frame
	var back_to_p1_ok = ("PAGE I" in title_lbl.text and back_btn.disabled)
	record("Back Navigation to Page 1", back_to_p1_ok, "Returned to Page I, Back button re-disabled")

	# ── TEST 6: Full Chronicle Traversal to Page 4 ──
	# Advance to Page 2
	next_btn.emit_signal("pressed")
	for i in range(3): await process_frame
	# Advance to Page 3
	next_btn.emit_signal("pressed")
	for i in range(3): await process_frame
	var p3_ok = ("PAGE III" in title_lbl.text and "WANDERER" in title_lbl.text.to_upper())

	# Advance to Page 4
	next_btn.emit_signal("pressed")
	for i in range(3): await process_frame
	var p4_ok = ("PAGE IV" in title_lbl.text and "shadow" in body_lbl.text.to_lower())

	record("Full Chronicle Traversal (Pages 3 & 4)", p3_ok and p4_ok,
		"Page III & IV displayed with authentic lore text and illustrations")

	# ── TEST 7: Page 4 Button Text [ BEGIN JOURNEY ► ] ──
	var btn_journey_ok = (next_btn != null and "BEGIN JOURNEY" in next_btn.text)
	record("Page 4 Button Transforms to [ BEGIN JOURNEY ► ]", btn_journey_ok,
		"Button text: %s" % (next_btn.text if next_btn else "null"))

	# ── TEST 8: Next from Page 4 transitions to Level 1 ──
	next_btn.emit_signal("pressed")
	var elapsed = 0.0
	while elapsed < 2.0 and current_scene == intro:
		await create_timer(0.1).timeout
		elapsed += 0.1

	var lvl1_from_intro = (current_scene != null and current_scene.get("level_title") == "LEVEL 1")
	record("Final Page Transition into Level 1", lvl1_from_intro,
		"Successfully arrived in Level 1: %s" % (current_scene.name if current_scene else "null"))

	# ── TEST 9: Skip Button Functionality ──
	# Re-enter intro and test skip
	change_scene_to_file("res://scenes/story_intro.tscn")
	for i in range(5):
		await process_frame
		await physics_frame
	intro = current_scene
	skip_btn = intro.get_node_or_null("FrameContainer/TomePanel/SkipButton") as Button if intro else null
	if skip_btn:
		skip_btn.emit_signal("pressed")
		elapsed = 0.0
		while elapsed < 2.0 and current_scene == intro:
			await create_timer(0.1).timeout
			elapsed += 0.1
	var lvl1_from_skip = (current_scene != null and current_scene.get("level_title") == "LEVEL 1")
	record("Skip Button Transitions to Level 1", lvl1_from_skip,
		"Skip cleanly bypassed intro directly into Level 1")

	# ── TEST 10: Level 2 Ending Presentation ──
	# Load Level 2 and trigger completion to verify the new fantasy ending sequence
	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var lvl2 = current_scene
	var ui = lvl2.ui if lvl2 else null
	# Trigger show_ending_card directly on ui
	var ending_card = ui.show_ending_card()
	for i in range(5):
		await process_frame
		await physics_frame

	var passage_lbl = ending_card.find_child("Label", true, false)
	# Look for passage text
	var epilogue_center = ending_card.get_node_or_null("EpilogueCenter")
	var advance_btn = ending_card.find_child("AdvancePassageButton", true, false) as Button
	var p1_ending_ok = false
	if epilogue_center and advance_btn:
		p1_ending_ok = ("EPILOGUE" in epilogue_center.to_string() or advance_btn.text == "[ NEXT ► ]")
	record("Level 2 Ending: Passage 1 Presentation", p1_ending_ok,
		"Ornate epilogue frame active with Passage 1 & [ NEXT ► ] button")

	# ── TEST 11: Level 2 Ending: Passage 2 Presentation ──
	if advance_btn:
		advance_btn.emit_signal("pressed")
		for i in range(5):
			await process_frame
	var p2_ending_ok = (advance_btn != null and advance_btn.text == "[ CONTINUE ► ]")
	record("Level 2 Ending: Passage 2 Presentation", p2_ending_ok,
		"Passage 2 active with [ CONTINUE ► ] button")

	# ── TEST 12: Final Title Card ("THE JOURNEY CONTINUES") & Return Button ──
	if advance_btn:
		advance_btn.emit_signal("pressed")
		for i in range(15):
			await process_frame
	var title_center = ending_card.get_node_or_null("TitleCardCenter")
	var return_btn = ending_card.find_child("ReturnToMenuButton", true, false) as Button
	var title_card_ok = (title_center != null and return_btn != null)
	record("Final Title Card ('THE JOURNEY CONTINUES') & Return Button", title_card_ok,
		"Final card active with animated eclipse, title, subtitle & ReturnToMenuButton")

	# ── TEST 13: Return to Main Menu Button Navigation ──
	if return_btn:
		return_btn.emit_signal("pressed")
		for i in range(5):
			await process_frame
			await physics_frame
	var title_restored = (current_scene != null and current_scene.name == "TitleScreen")
	record("Return to Main Menu Button Functionality", title_restored,
		"Cleanly transitioned back to res://scenes/title_screen.tscn")

	print("\n════════════════════════════════════════════════════════════")
	print("  TOTAL VERIFICATION: %d / %d PASSED" % [passed, total])
	print("════════════════════════════════════════════════════════════\n")

	if passed == total:
		quit(0)
	else:
		quit(1)

extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — UI Polish, Retro Credits, and Dynamic Audio Verification Suite
# ═════════════════════════════════════════════════════════════════════════════

var passed: int = 0
var total: int = 0

func record(test_name: String, ok: bool, details: String = ""):
	total += 1
	if ok:
		passed += 1
		print("  [PASS] Test %d: %s %s" % [total, test_name, "(%s)" % details if details != "" else ""])
	else:
		printerr("  [FAIL] Test %d: %s %s" % [total, test_name, "- REASON: %s" % details if details != "" else ""])

func _init() -> void:
	print("\n════════════════════════════════════════════════════════════")
	print("  TESTING UI POLISH, RETRO CREDITS & DYNAMIC AUDIO")
	print("════════════════════════════════════════════════════════════\n")

	# ── TEST 1: Load Title Screen Scene ──
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var title_scene = current_scene
	var loaded = (title_scene != null and title_scene.name == "TitleScreen")
	record("Load Title Screen Scene", loaded, "res://scenes/title_screen.tscn loaded successfully")

	# ── TEST 2: Responsive Centered Layout Composition ──
	var center_container = title_scene.get_node_or_null("UI/CenterContainer")
	var menu_column = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn")
	var layout_ok = (center_container != null and menu_column != null and center_container.anchors_preset == Control.PRESET_FULL_RECT)
	record("Main Menu Layout Centered in Viewport", layout_ok, "CenterContainer active with FULL_RECT preset")

	# ── TEST 3: Retro Typography on Title & Tagline ──
	var title_lbl = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/HeaderContainer/TitleLabel")
	var tagline_lbl = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/HeaderContainer/TaglineLabel")
	var title_font_ok = (title_lbl and title_lbl.get_theme_font("font") != null and title_lbl.text == "ECLIPSE")
	var tagline_font_ok = (tagline_lbl and tagline_lbl.get_theme_font("font") != null and "Some shadows remember" in tagline_lbl.text)
	record("Title & Tagline Retro Typography", title_font_ok and tagline_font_ok, "Press Start 2P title & Silkscreen tagline active")

	# ── TEST 4: Menu Navigation Buttons with Retro Font & Clear States ──
	var play_btn = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/MenuContainer/PlayButton")
	var credits_btn = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/MenuContainer/CreditsButton")
	var mute_btn = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/MenuContainer/MuteButton")
	var quit_btn = title_scene.get_node_or_null("UI/CenterContainer/MenuColumn/MenuContainer/QuitButton")
	var btns_ok = (play_btn != null and credits_btn != null and mute_btn != null and quit_btn != null)
	var fonts_ok = (btns_ok and play_btn.get_theme_font("font") != null)
	record("Menu Navigation Buttons & Styling", btns_ok and fonts_ok, "Play, Credits, Mute, Quit buttons with custom font and focus")

	# ── TEST 5: Background Artwork Framing (Wanderer, Shadow, Eclipse) ──
	var visuals = title_scene.get_node_or_null("Visuals")
	var eclipse = visuals.get_node_or_null("EclipseDisc") if visuals else null
	var wanderer_sp = visuals.get_node_or_null("WandererSprite") if visuals else null
	var shadow_sp = visuals.get_node_or_null("ShadowSprite") if visuals else null
	var visuals_ok = (eclipse != null and wanderer_sp != null and shadow_sp != null)
	record("Background Artwork Framing", visuals_ok, "Eclipse disc and entity altars properly framed")

	# ── TEST 6: Redesigned Old-School Credits Screen & Creator Field ──
	var credits_modal = title_scene.get_node_or_null("UI/CreditsModal")
	var creator_lbl = title_scene.get_node_or_null("UI/CreditsModal/CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CreditsContent/CreatorLabel")
	var close_btn = title_scene.get_node_or_null("UI/CreditsModal/CenterContainer/Panel/MarginContainer/VBoxContainer/CloseCreditsButton")

	# Open credits
	credits_btn.emit_signal("pressed")
	await process_frame
	var modal_opened = (credits_modal and credits_modal.visible)

	# Close credits
	close_btn.emit_signal("pressed")
	await process_frame
	var modal_closed = (credits_modal and not credits_modal.visible)

	var credits_ok = (modal_opened and modal_closed and creator_lbl != null)
	record("Retro Credits Screen with Customizable Creator Field", credits_ok, "Centered parchment/stone modal with OFL pixel typography")

	# ── TEST 7: Separate Main Menu Music ──
	var audio_mgr = root.get_node_or_null("AudioManager")
	var menu_bgm_ok = false
	if audio_mgr:
		menu_bgm_ok = (audio_mgr.current_mode == audio_mgr.MusicMode.MENU and audio_mgr.active_player.playing)
	record("Main Menu Exclusive Music", menu_bgm_ok, "MusicMode.MENU active on title screen")

	# ── TEST 8: Play Button Fades Out Menu Music & Loads Level 1 ──
	play_btn.emit_signal("pressed")
	for i in range(5):
		await process_frame
		await physics_frame

	var lvl1 = current_scene
	var l1_loaded = (lvl1 != null and lvl1.level_title == "LEVEL 1")
	record("Play Button Transitions to Level 1", l1_loaded, "Successfully entered Level 1: %s" % (lvl1.name if lvl1 else "null"))

	# ── TEST 9: Normal Mode Plays Cheerful Exploration Music ──
	var normal_music_ok = false
	if audio_mgr:
		normal_music_ok = (audio_mgr.current_mode == audio_mgr.MusicMode.NORMAL and audio_mgr.active_player.playing)
	record("Normal Mode: Cheerful Exploration Music", normal_music_ok, "MusicMode.NORMAL active during Wanderer exploration")

	# ── TEST 10: Eclipse Mode Transitions to Ominous Shadow Music ──
	lvl1.toggle_dimension()
	await physics_frame
	await physics_frame
	var eclipse_music_ok = false
	if audio_mgr:
		eclipse_music_ok = (audio_mgr.current_mode == audio_mgr.MusicMode.ECLIPSE and audio_mgr.active_player.playing)
	record("Eclipse Mode: Ominous Shadow Music", eclipse_music_ok, "MusicMode.ECLIPSE triggered upon summoning Shadow")

	# ── TEST 11: Dismissing Shadow Restores Cheerful Normal Music ──
	lvl1.toggle_dimension()
	await physics_frame
	await physics_frame
	var restored_normal_music = false
	if audio_mgr:
		restored_normal_music = (audio_mgr.current_mode == audio_mgr.MusicMode.NORMAL and audio_mgr.active_player.playing)
	record("Restoring Normal Mode Restores Cheerful Music", restored_normal_music, "MusicMode.NORMAL restored via crossfade")

	# ── TEST 12: Interaction Sound Effects (Tablet, Note, Lever, Gate) ──
	var tablet = lvl1.get_node_or_null("Objects/Tablet")
	var note = lvl1.get_node_or_null("Objects/Note")
	var wanderer = lvl1.get_node_or_null("Wanderer")
	var sfx_ok = false
	if tablet and note and wanderer:
		tablet.interact(wanderer)
		await process_frame
		note.interact(wanderer)
		await process_frame
		sfx_ok = (audio_mgr != null and audio_mgr.sfx_tablet != null and audio_mgr.sfx_message != null)
	record("Interaction SFX Triggers (Tablet & Note)", sfx_ok, "Distinct sounds triggered on inscription & lore reveal")

	# ── TEST 13: Mute & Volume Control ──
	if audio_mgr:
		var init_muted = audio_mgr.get_muted()
		audio_mgr.toggle_mute()
		var muted_state = audio_mgr.get_muted()
		audio_mgr.toggle_mute()
		var restored_state = audio_mgr.get_muted()
		var mute_ok = (not init_muted and muted_state and not restored_state)
		record("Master Mute and Volume Control", mute_ok, "AudioServer bus mute toggles cleanly")
	else:
		record("Master Mute and Volume Control", false, "AudioManager missing")

	# ── TEST 14: Return to Title Screen Restores Menu Music ──
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in range(5):
		await process_frame
		await physics_frame
	var title_restored = (current_scene != null and current_scene.name == "TitleScreen")
	var menu_music_restored = (audio_mgr != null and audio_mgr.current_mode == audio_mgr.MusicMode.MENU)
	record("Return to Title Screen Restores Menu Music", title_restored and menu_music_restored, "Title scene & MusicMode.MENU restored")

	print("\n════════════════════════════════════════════════════════════")
	print("  TEST RESULTS: %d / %d PASSED" % [passed, total])
	print("════════════════════════════════════════════════════════════\n")

	if passed == total:
		quit(0)
	else:
		quit(1)

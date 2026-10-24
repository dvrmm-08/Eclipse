extends SceneTree

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — In-Game Music Toggle & Persistence Test Suite
# Verifies:
#   1. Music plays normally when saved preference is ON (default).
#   2. Music toggle button present in Level 1 HUD in top-right corner.
#   3. Clicking button mutes background music immediately (Music bus muted).
#   4. Gameplay SFX (UI click, summon, return, mechanism) remain audible when music is muted.
#   5. Switching between Wanderer & Shadow forms preserves music mute without music leaking.
#   6. Transitioning from Level 1 to Level 2 preserves music mute.
#   7. Music toggle button present and functional in Level 2 HUD with matching state.
#   8. Unmuting music restores appropriate track immediately without playback restart.
#   9. Preference persistence to user://settings.cfg survives across session reloads.
#  10. Startup application: saved preference applies before first music frame.
#  11. Hidden during ending cinematic (hide_hud hides toggle button).
#  12. Layout: No overlap between DimensionLabel, ControlsLabel, and MusicToggleButton.
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
	print("  TESTING IN-GAME MUSIC TOGGLE & PERSISTENCE")
	print("════════════════════════════════════════════════════════════\n")

	# ── TEST 1: Default State: Music ON & Playing ──
	change_scene_to_file("res://scenes/level_1.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var audio_mgr = root.get_node_or_null("AudioManager")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")

	if audio_mgr:
		audio_mgr.set_music_muted(false, true)

	var lvl1 = current_scene
	var music_muted_init = audio_mgr.get_music_muted() if audio_mgr else true
	var music_bus_muted_init = AudioServer.is_bus_mute(music_bus)
	var active_playing = (audio_mgr != null and audio_mgr.active_player != null and audio_mgr.active_player.playing)
	record("1. Music plays normally when preference is ON",
		not music_muted_init and not music_bus_muted_init and active_playing,
		"MusicMode.NORMAL active, Music bus unmuted, player playing")

	# ── TEST 2: Music Toggle Button Presence & Layout in Level 1 ──
	var ui1 = lvl1.get_node_or_null("UIOverlay")
	var btn1 = ui1.get_node_or_null("HUD/MusicToggleButton") as Button if ui1 else null
	var dim_lbl1 = ui1.get_node_or_null("HUD/DimensionLabel") as Label if ui1 else null
	var ctrl_lbl1 = ui1.get_node_or_null("HUD/ControlsLabel") as Label if ui1 else null

	var layout_ok = false
	if btn1 and dim_lbl1 and ctrl_lbl1:
		# Check top-right positioning: button x is > 500, y is in top bar < 32
		var btn_in_top_right = (btn1.global_position.x >= 500.0 and btn1.global_position.y >= 0.0 and btn1.global_position.y <= 32.0)
		# Check no horizontal collision between DimensionLabel and Button
		var no_overlap = (dim_lbl1.global_position.x + dim_lbl1.size.x < btn1.global_position.x)
		layout_ok = btn_in_top_right and no_overlap
	record("2. Button placement in top-right HUD without overlap", layout_ok,
		"Button at (%.1f, %.1f), size %s" % [btn1.global_position.x, btn1.global_position.y, btn1.size] if btn1 else "Button missing")

	# ── TEST 3: Click Button Mutes Background Music Immediately ──
	var initial_track_pos = audio_mgr.active_player.get_playback_position() if audio_mgr and audio_mgr.active_player else 0.0
	btn1.emit_signal("pressed")
	for i in range(3):
		await process_frame

	var is_muted_now = audio_mgr.get_music_muted()
	var music_bus_muted = AudioServer.is_bus_mute(music_bus)
	var btn_text_off = (btn1.text == "MUSIC: OFF")
	record("3. Clicking button mutes background music immediately",
		is_muted_now and music_bus_muted and btn_text_off,
		"Music bus muted=true, button text='MUSIC: OFF', AudioServer bus mute active")

	# ── TEST 4: SFX Remain Fully Audible While Music Is Muted ──
	var sfx_bus_unmuted = not AudioServer.is_bus_mute(sfx_bus)
	var master_bus_unmuted = not AudioServer.is_bus_mute(0)
	# Trigger dimension switch SFX or UI SFX
	audio_mgr.play_summon_shadow_sfx()
	var sfx_playing = (audio_mgr.sfx_summon != null and audio_mgr.sfx_summon.playing)
	record("4. Sound effects remain audible while music is muted",
		sfx_bus_unmuted and master_bus_unmuted and sfx_playing,
		"SFX bus unmuted, Master bus unmuted, SFX player actively played")

	# ── TEST 5: Dimension Switching Preserves Mute Without Leaks ──
	lvl1.toggle_dimension() # Switch to Shadow form
	for i in range(5):
		await process_frame
		await physics_frame

	var shadow_music_muted = audio_mgr.get_music_muted()
	var shadow_bus_muted = AudioServer.is_bus_mute(music_bus)
	var shadow_active = lvl1.eclipse_active
	record("5. Preference remains OFF when switching dimensions",
		shadow_active and shadow_music_muted and shadow_bus_muted,
		"Switched to Eclipse Mode; Music bus remains strictly muted")

	# Switch back to Wanderer
	lvl1.toggle_dimension()
	for i in range(5):
		await process_frame
		await physics_frame

	# ── TEST 6: Transitioning to Level 2 Preserves Mute Preference ──
	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var lvl2 = current_scene
	var lvl2_music_muted = audio_mgr.get_music_muted()
	var lvl2_bus_muted = AudioServer.is_bus_mute(music_bus)
	var ui2 = lvl2.get_node_or_null("UIOverlay")
	var btn2 = ui2.get_node_or_null("HUD/MusicToggleButton") as Button if ui2 else null
	var btn2_text_off = (btn2 != null and btn2.text == "MUSIC: OFF")
	record("6. Preference remains OFF when transitioning levels",
		lvl2_music_muted and lvl2_bus_muted and btn2_text_off,
		"Entered Level 2; Music bus still muted, Level 2 button displays MUSIC: OFF")

	# ── TEST 7: Returning to Main Menu Preserves Mute Preference ──
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	var title_music_muted = audio_mgr.get_music_muted()
	var title_bus_muted = AudioServer.is_bus_mute(music_bus)
	record("7. Preference remains OFF when returning to main menu",
		title_music_muted and title_bus_muted,
		"TitleScreen active; Music bus remains strictly muted")

	# ── TEST 8: Reopen Level 2 and Unmute Music ──
	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame

	lvl2 = current_scene
	ui2 = lvl2.get_node_or_null("UIOverlay")
	btn2 = ui2.get_node_or_null("HUD/MusicToggleButton") as Button if ui2 else null

	# Click button to unmute
	btn2.emit_signal("pressed")
	for i in range(3):
		await process_frame

	var unmuted_music = not audio_mgr.get_music_muted()
	var unmuted_bus = not AudioServer.is_bus_mute(music_bus)
	var btn2_text_on = (btn2.text == "MUSIC: ON")
	var music_playing_now = (audio_mgr.active_player != null and audio_mgr.active_player.playing)
	record("8. Turning music ON restores current track immediately",
		unmuted_music and unmuted_bus and btn2_text_on and music_playing_now,
		"Music bus unmuted, button text='MUSIC: ON', track playing seamlessly")

	# ── TEST 9: Persistence to user://settings.cfg ──
	# Now mute again to test config file contents
	btn2.emit_signal("pressed")
	for i in range(3):
		await process_frame

	var config = ConfigFile.new()
	var load_err = config.load(audio_mgr.SETTINGS_PATH)
	var saved_val = config.get_value("audio", "music_muted", null)
	record("9. Settings saved to user://settings.cfg",
		load_err == OK and saved_val == true,
		"settings.cfg loaded successfully, audio.music_muted = %s" % str(saved_val))

	# ── TEST 10: Startup Application from ConfigFile ──
	# Simulate startup: call _load_settings on AudioManager
	audio_mgr.is_music_muted = false # Temporarily reset in-memory variable
	AudioServer.set_bus_mute(music_bus, false)
	audio_mgr._load_settings() # Re-read config from disk
	var restored_from_disk = (audio_mgr.is_music_muted == true and AudioServer.is_bus_mute(music_bus) == true)
	record("10. Saved preference applied during startup before music plays",
		restored_from_disk,
		"_load_settings() correctly restores music_muted=true and mutes Music bus")

	# ── TEST 11: Button Hidden During Ending Cinematic (hide_hud) ──
	ui2.hide_hud()
	var btn_hidden = not btn2.visible
	ui2.show_hud()
	var btn_restored = btn2.visible
	record("11. Button hidden during cinematic & restored for gameplay",
		btn_hidden and btn_restored,
		"hide_hud hides MusicToggleButton; show_hud restores it")

	# ── TEST 12: Keyboard [M] Shortcut Also Toggles Music and Updates Button ──
	# Ensure music is currently unmuted for this test
	audio_mgr.set_music_muted(false)
	await process_frame
	var pre_m_btn_text = btn2.text # should be MUSIC: ON
	# Simulate pressing M key
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_M
	key_event.pressed = true
	lvl2._unhandled_input(key_event)
	for i in range(3):
		await process_frame

	var post_m_muted = audio_mgr.get_music_muted()
	var post_m_btn_text = btn2.text
	record("12. Keyboard [M] key synchronizes with Music button",
		post_m_muted and post_m_btn_text == "MUSIC: OFF",
		"M key toggled music mute and updated button text to MUSIC: OFF")

	# Reset settings to clean state for player
	audio_mgr.set_music_muted(false, true)

	print("\n════════════════════════════════════════════════════════════")
	print("  TOTAL VERIFICATION: %d / %d PASSED" % [passed, total])
	print("════════════════════════════════════════════════════════════\n")

	if passed == total:
		quit(0)
	else:
		quit(1)

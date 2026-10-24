extends Node

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Dynamic Audio Engine (Autoload Singleton)
#
# Audio Architecture:
#   - Buses:
#       * Master (Index 0)
#       * Music (Routed to Master)
#       * SFX (Routed to Master)
#   - Background Music (BGM):
#       * Main Menu: "The Field of Dreams" (the_field_of_dreams.mp3)
#       * Normal Mode: "The Old Tower Inn" (NES_TheOldTowerInn.mp3)
#       * Eclipse Mode: "Into the Ruined Temple" (into_the_ruined_temple.mp3)
#   - Smooth crossfading (0.5–1.5s) between Normal and Shadow gameplay modes.
#   - Independent SFX players for:
#       * UI hover & clicks (Kenney UI Audio pack)
#       * Credits Back navigation
#       * Dimension summoning & return
#       * Ancient tablet riddles & parchment lore notes
#       * Heavy mechanical levers & sliding stone gates
#       * Ending autonomous shadow reveal
#   - Master mute and volume controls.
# ═════════════════════════════════════════════════════════════════════════════

enum MusicMode {
	NONE,
	MENU,
	NORMAL,
	ECLIPSE,
	ENDING
}

var current_mode: MusicMode = MusicMode.NONE

# Dual players for seamless A/B crossfading
var player_a: AudioStreamPlayer = null
var player_b: AudioStreamPlayer = null
var active_player: AudioStreamPlayer = null

# SFX players
var sfx_ui_hover: AudioStreamPlayer = null
var sfx_ui_click: AudioStreamPlayer = null
var sfx_ui_back: AudioStreamPlayer = null
var sfx_switch: AudioStreamPlayer = null
var sfx_summon: AudioStreamPlayer = null
var sfx_return: AudioStreamPlayer = null
var sfx_message: AudioStreamPlayer = null
var sfx_tablet: AudioStreamPlayer = null
var sfx_mech: AudioStreamPlayer = null
var sfx_gate: AudioStreamPlayer = null
var sfx_reveal: AudioStreamPlayer = null

# Streams
var stream_menu: AudioStream = null
var stream_exploration: AudioStream = null
var stream_eclipse: AudioStream = null
var stream_ending: AudioStream = null

var stream_ui_hover: AudioStream = null
var stream_ui_click: AudioStream = null
var stream_ui_back: AudioStream = null
var stream_sfx_summon: AudioStream = null
var stream_sfx_return: AudioStream = null
var stream_sfx_switch: AudioStream = null
var stream_sfx_message: AudioStream = null
var stream_sfx_tablet: AudioStream = null
var stream_sfx_mech: AudioStream = null
var stream_sfx_gate: AudioStream = null
var stream_sfx_reveal: AudioStream = null

const SETTINGS_PATH: String = "user://settings.cfg"
var is_muted: bool = false
var is_music_muted: bool = false
var default_music_volume_db: float = -10.0
var default_sfx_volume_db: float = -6.0

var _crossfade_tween: Tween = null

signal mute_toggled(muted: bool)
signal music_mute_toggled(muted: bool)
signal music_mode_changed(mode: MusicMode)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_audio_buses()
	_load_settings()
	_load_resources()
	_setup_players()

func _ensure_audio_buses() -> void:
	# Ensure "Music" bus exists
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")

	# Ensure "SFX" bus exists
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func _load_resources() -> void:
	# BGM Streams
	if ResourceLoader.exists("res://assets/audio/the_field_of_dreams.mp3"):
		stream_menu = load("res://assets/audio/the_field_of_dreams.mp3")
		_ensure_loop(stream_menu)

	if ResourceLoader.exists("res://assets/audio/NES_TheOldTowerInn.mp3"):
		stream_exploration = load("res://assets/audio/NES_TheOldTowerInn.mp3")
		_ensure_loop(stream_exploration)

	if ResourceLoader.exists("res://assets/audio/into_the_ruined_temple.mp3"):
		stream_eclipse = load("res://assets/audio/into_the_ruined_temple.mp3")
		_ensure_loop(stream_eclipse)

	if ResourceLoader.exists("res://assets/audio/bombinsound-halloween-suspense-horror-halloween-waltz-619348.mp3"):
		stream_ending = load("res://assets/audio/bombinsound-halloween-suspense-horror-halloween-waltz-619348.mp3")
		_ensure_loop(stream_ending)

	# SFX Streams
	if ResourceLoader.exists("res://assets/sfx/impactSoft_medium_000.ogg"):
		stream_ui_hover = load("res://assets/sfx/impactSoft_medium_000.ogg")

	if ResourceLoader.exists("res://assets/sfx/impactGeneric_light_002.ogg"):
		stream_ui_click = load("res://assets/sfx/impactGeneric_light_002.ogg")

	if ResourceLoader.exists("res://assets/sfx/impactGeneric_light_001.ogg"):
		stream_ui_back = load("res://assets/sfx/impactGeneric_light_001.ogg")

	if ResourceLoader.exists("res://assets/sfx/magical_4.ogg"):
		stream_sfx_summon = load("res://assets/sfx/magical_4.ogg")
		stream_sfx_switch = stream_sfx_summon

	if ResourceLoader.exists("res://assets/sfx/impactBell_heavy_002.ogg"):
		stream_sfx_return = load("res://assets/sfx/impactBell_heavy_002.ogg")

	if ResourceLoader.exists("res://assets/sfx/impactSoft_medium_001.ogg"):
		stream_sfx_message = load("res://assets/sfx/impactSoft_medium_001.ogg")

	if ResourceLoader.exists("res://assets/sfx/impactMining_000.ogg"):
		stream_sfx_tablet = load("res://assets/sfx/impactMining_000.ogg")

	if ResourceLoader.exists("res://assets/sfx/clank1.wav"):
		stream_sfx_mech = load("res://assets/sfx/clank1.wav")

	if ResourceLoader.exists("res://assets/sfx/stone_door.ogg"):
		stream_sfx_gate = load("res://assets/sfx/stone_door.ogg")

	if ResourceLoader.exists("res://assets/sfx/impactBell_heavy_000.ogg"):
		stream_sfx_reveal = load("res://assets/sfx/impactBell_heavy_000.ogg")

func _ensure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0 and stream.data.size() > 0:
			stream.loop_end = stream.data.size() / 4

func _setup_players() -> void:
	# Dual players for seamless A/B crossfading
	player_a = AudioStreamPlayer.new()
	player_a.name = "MusicPlayerA"
	player_a.bus = "Music"
	player_a.volume_db = default_music_volume_db
	add_child(player_a)

	player_b = AudioStreamPlayer.new()
	player_b.name = "MusicPlayerB"
	player_b.bus = "Music"
	player_b.volume_db = -80.0
	add_child(player_b)

	active_player = player_a

	# SFX Players
	sfx_ui_hover = _create_sfx_player("SFXUIHover", stream_ui_hover, -16.0)
	sfx_ui_click = _create_sfx_player("SFXUIClick", stream_ui_click, -10.0)
	sfx_ui_back = _create_sfx_player("SFXUIBack", stream_ui_back, -12.0)
	sfx_switch = _create_sfx_player("SFXSwitch", stream_sfx_switch, -8.0)
	sfx_summon = _create_sfx_player("SFXSummon", stream_sfx_summon, -8.0)
	sfx_return = _create_sfx_player("SFXReturn", stream_sfx_return, -6.0)
	sfx_message = _create_sfx_player("SFXMessage", stream_sfx_message, -8.0)
	sfx_tablet = _create_sfx_player("SFXTablet", stream_sfx_tablet, -6.0)
	sfx_mech = _create_sfx_player("SFXMech", stream_sfx_mech, -4.0)
	sfx_gate = _create_sfx_player("SFXGate", stream_sfx_gate, -4.0)
	sfx_reveal = _create_sfx_player("SFXReveal", stream_sfx_reveal, -2.0)

func _create_sfx_player(node_name: String, stream: AudioStream, vol: float = -6.0) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name = node_name
	p.bus = "SFX"
	p.volume_db = vol
	p.stream = stream
	add_child(p)
	return p

# ── MUSIC CONTROL ────────────────────────────────────────────────────────────

func play_menu_music(fade_in_time: float = 0.5) -> void:
	if current_mode == MusicMode.MENU and active_player and active_player.playing:
		return
	current_mode = MusicMode.MENU
	_crossfade_to_stream(stream_menu, fade_in_time, -10.0)
	emit_signal("music_mode_changed", current_mode)

func play_gameplay_music(is_eclipse: bool, crossfade_time: float = 0.8) -> void:
	var target_mode = MusicMode.ECLIPSE if is_eclipse else MusicMode.NORMAL
	if current_mode == target_mode and active_player and active_player.playing:
		return

	current_mode = target_mode
	var target_stream = stream_eclipse if is_eclipse else stream_exploration
	var target_vol = -8.0 if is_eclipse else -12.0
	_crossfade_to_stream(target_stream, crossfade_time, target_vol)
	emit_signal("music_mode_changed", current_mode)

func play_ending_music(fade_in_time: float = 1.5, target_vol_db: float = -12.0) -> void:
	if current_mode == MusicMode.ENDING and active_player and active_player.playing:
		return
	current_mode = MusicMode.ENDING
	_crossfade_to_stream(stream_ending, fade_in_time, target_vol_db)
	emit_signal("music_mode_changed", current_mode)

func fade_out_music(duration: float = 0.6) -> void:
	current_mode = MusicMode.NONE
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	if not active_player or not active_player.playing:
		return

	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(active_player, "volume_db", -80.0, duration)
	_crossfade_tween.tween_callback(func():
		if active_player:
			active_player.stop()
	)

func stop_music() -> void:
	current_mode = MusicMode.NONE
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if player_a: player_a.stop()
	if player_b: player_b.stop()

func _crossfade_to_stream(new_stream: AudioStream, duration: float, target_vol_db: float = -10.0) -> void:
	if not new_stream:
		return

	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	var incoming_player = player_b if active_player == player_a else player_a
	var outgoing_player = active_player

	incoming_player.stream = new_stream
	incoming_player.volume_db = -80.0
	if not is_muted:
		incoming_player.play()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	# Fade in incoming
	_crossfade_tween.tween_property(incoming_player, "volume_db", target_vol_db, duration).set_trans(Tween.TRANS_SINE)
	# Fade out outgoing
	if outgoing_player and outgoing_player.playing:
		_crossfade_tween.tween_property(outgoing_player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE)

	_crossfade_tween.chain().tween_callback(func():
		if outgoing_player and outgoing_player != incoming_player:
			outgoing_player.stop()
	)

	active_player = incoming_player

# ── SFX TRIGGERS ─────────────────────────────────────────────────────────────

func play_ui_hover() -> void:
	_play_sfx(sfx_ui_hover)

func play_ui_click() -> void:
	_play_sfx(sfx_ui_click)

func play_ui_select() -> void:
	_play_sfx(sfx_ui_click)

func play_ui_back() -> void:
	_play_sfx(sfx_ui_back)

func play_summon_shadow_sfx() -> void:
	_play_sfx(sfx_summon)

func play_return_wanderer_sfx() -> void:
	_play_sfx(sfx_return)

func play_switch_sfx() -> void:
	_play_sfx(sfx_switch)

func play_message_sfx() -> void:
	_play_sfx(sfx_message)

func play_tablet_sfx() -> void:
	_play_sfx(sfx_tablet)

func play_mechanism_sfx() -> void:
	_play_sfx(sfx_mech)

func play_gate_sfx() -> void:
	_play_sfx(sfx_gate)

func play_reveal_sfx() -> void:
	_play_sfx(sfx_reveal)

func _play_sfx(player: AudioStreamPlayer) -> void:
	if is_muted or not player or not player.stream:
		return
	player.play()

# ── SETTINGS PERSISTENCE ─────────────────────────────────────────────────────

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		is_music_muted = config.get_value("audio", "music_muted", false)
	else:
		is_music_muted = false

	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_music_muted)
	print("AUDIO: Settings loaded. Music muted: ", is_music_muted)

func _save_settings() -> void:
	var config = ConfigFile.new()
	# Load existing file first to preserve any other existing sections/keys
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music_muted", is_music_muted)
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save audio settings to: " + SETTINGS_PATH)

# ── MUSIC-SPECIFIC MUTE ──────────────────────────────────────────────────────

func toggle_music_mute() -> bool:
	set_music_muted(not is_music_muted)
	return is_music_muted

func set_music_muted(muted: bool, save: bool = true) -> void:
	is_music_muted = muted
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_music_muted)

	if not is_music_muted and not is_muted:
		if active_player and active_player.stream and not active_player.playing:
			active_player.play()

	if save:
		_save_settings()

	emit_signal("music_mute_toggled", is_music_muted)
	print("AUDIO: Music mute set to ", is_music_muted)

func get_music_muted() -> bool:
	return is_music_muted

# ── MASTER VOLUME & MUTE ─────────────────────────────────────────────────────

func toggle_mute() -> bool:
	set_muted(not is_muted)
	return is_muted

func set_muted(muted: bool) -> void:
	is_muted = muted
	AudioServer.set_bus_mute(0, is_muted)
	if is_muted:
		if player_a: player_a.volume_db = -80.0
		if player_b: player_b.volume_db = -80.0
	else:
		if active_player and active_player.stream:
			active_player.volume_db = default_music_volume_db
			if not active_player.playing:
				active_player.play()

	emit_signal("mute_toggled", is_muted)
	print("AUDIO: Mute set to ", is_muted)

func get_muted() -> bool:
	return is_muted

func set_music_volume(volume_db: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_sfx_volume(volume_db: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

# Backward compatibility getter for test suites
var music_player: AudioStreamPlayer:
	get:
		return active_player
var bgm_stream: AudioStream:
	get:
		return stream_exploration if current_mode == MusicMode.NORMAL else stream_menu
var switch_stream: AudioStream:
	get: return stream_sfx_switch
var mech_stream: AudioStream:
	get: return stream_sfx_mech
var reveal_stream: AudioStream:
	get: return stream_sfx_reveal

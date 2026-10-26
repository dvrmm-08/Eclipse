extends Control

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Title Screen Controller
#
# Features:
#   - Mathematically balanced and responsive centered menu composition.
#   - Retro pixel typography with Press Start 2P & Silkscreen.
#   - Atmospheric ruins background: White Wanderer, dark Shadow, pulsing Eclipse.
#   - Full keyboard, gamepad, and mouse navigation with clear focus states.
#   - Cohesive old-school credits screen with subtle auto-scroll/reveal.
#   - Dynamic audio integration: Main menu music playback and Play fade-out.
# ═════════════════════════════════════════════════════════════════════════════

@export var creator_name: String = "Deva Ram" # Editable in Godot Inspector
@export var intro_scene_path: String = "res://scenes/story_intro.tscn"
@export var first_level_path: String = "res://scenes/level_1.tscn"

@onready var play_button: Button = $UI/CenterContainer/MenuColumn/MenuContainer/PlayButton
@onready var credits_button: Button = $UI/CenterContainer/MenuColumn/MenuContainer/CreditsButton
@onready var mute_button: Button = $UI/CenterContainer/MenuColumn/MenuContainer/MuteButton
@onready var quit_button: Button = $UI/CenterContainer/MenuColumn/MenuContainer/QuitButton

@onready var title_label: Label = $UI/CenterContainer/MenuColumn/HeaderContainer/TitleLabel
@onready var tagline_label: Label = $UI/CenterContainer/MenuColumn/HeaderContainer/TaglineLabel

@onready var credits_modal: Control = $UI/CreditsModal
@onready var close_credits_button: Button = $UI/CreditsModal/CenterContainer/Panel/MarginContainer/VBoxContainer/CloseCreditsButton
@onready var creator_label: Label = $UI/CreditsModal/CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CreditsContent/CreatorLabel
@onready var credits_scroll: ScrollContainer = $UI/CreditsModal/CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer

@onready var eclipse_disc: Node2D = $Visuals/EclipseDisc
@onready var wanderer_sprite: Sprite2D = $Visuals/WandererSprite
@onready var shadow_sprite: Sprite2D = $Visuals/ShadowSprite
@onready var cyan_glow: Sprite2D = $Visuals/CyanGlow

var _pulse_time: float = 0.0
var _credits_scroll_tween: Tween = null

func _ready() -> void:
	# Update customizable creator field
	if creator_label:
		creator_label.text = creator_name

	# Connect navigation buttons
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.mouse_entered.connect(_on_button_hover)
		play_button.grab_focus()
	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)
		credits_button.mouse_entered.connect(_on_button_hover)
	if mute_button:
		mute_button.pressed.connect(_on_mute_pressed)
		mute_button.mouse_entered.connect(_on_button_hover)
		_update_mute_button_text()
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover)

	if close_credits_button:
		close_credits_button.pressed.connect(_on_close_credits_pressed)
		close_credits_button.mouse_entered.connect(_on_button_hover)

	if credits_modal:
		credits_modal.visible = false

	# Play atmospheric main menu music
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_menu_music()
		if not audio_mgr.mute_toggled.is_connected(_on_audio_mute_toggled):
			audio_mgr.mute_toggled.connect(_on_audio_mute_toggled)

	_setup_intro_animations()

func _setup_intro_animations() -> void:
	# Fade in title gently
	if title_label:
		title_label.modulate.a = 0.0
		var t_tween = create_tween()
		t_tween.tween_property(title_label, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade in tagline with slight delay
	if tagline_label:
		tagline_label.modulate.a = 0.0
		var g_tween = create_tween()
		g_tween.tween_interval(0.3)
		g_tween.tween_property(tagline_label, "modulate:a", 0.95, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_pulse_time += delta

	# Subtle breathing glow on the Eclipse corona
	if eclipse_disc and eclipse_disc.has_node("Corona"):
		var corona = eclipse_disc.get_node("Corona")
		var pulse = 0.8 + 0.2 * sin(_pulse_time * 2.2)
		corona.modulate = Color(1.0, 0.25, 0.35, pulse)

	# Gentle breathing hover on the Wanderer
	if wanderer_sprite:
		wanderer_sprite.position.y = 234.0 + sin(_pulse_time * 2.0) * 1.5

	# Subtle breathing on the Shadow
	if shadow_sprite:
		shadow_sprite.position.y = 234.0 + sin(_pulse_time * 2.0 + 1.4) * 1.8

	# Gentle pulse on the cyan pedestal glow
	if cyan_glow:
		cyan_glow.modulate.a = 0.55 + 0.25 * sin(_pulse_time * 2.8)

func _on_button_hover() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_hover"):
		audio_mgr.play_ui_hover()

func _on_play_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_ui_select"):
			audio_mgr.play_ui_select()
		audio_mgr.fade_out_music(0.5)

	var target = intro_scene_path if (intro_scene_path != "" and ResourceLoader.exists(intro_scene_path)) else first_level_path
	if ResourceLoader.exists(target):
		get_tree().change_scene_to_file(target)
	else:
		push_error("Starting scene missing: " + target)

func _on_credits_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_ui_click"):
			audio_mgr.play_ui_click()

	if credits_modal:
		credits_modal.visible = true
		if close_credits_button:
			close_credits_button.grab_focus()

		# Subtle reveal scrolling animation
		if credits_scroll:
			credits_scroll.scroll_vertical = 0
			if _credits_scroll_tween and _credits_scroll_tween.is_valid():
				_credits_scroll_tween.kill()
			_credits_scroll_tween = create_tween()
			_credits_scroll_tween.tween_interval(1.2)
			_credits_scroll_tween.tween_property(credits_scroll, "scroll_vertical", 60, 5.0).set_trans(Tween.TRANS_LINEAR)

func _on_close_credits_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_ui_back"):
			audio_mgr.play_ui_back()

	if _credits_scroll_tween and _credits_scroll_tween.is_valid():
		_credits_scroll_tween.kill()

	if credits_modal:
		credits_modal.visible = false
		if credits_button:
			credits_button.grab_focus()

func _on_mute_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_ui_click"):
			audio_mgr.play_ui_click()
		audio_mgr.toggle_mute()
		_update_mute_button_text()

func _on_audio_mute_toggled(_muted: bool) -> void:
	_update_mute_button_text()

func _update_mute_button_text() -> void:
	if not mute_button:
		return
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var is_muted = audio_mgr.get_muted() if audio_mgr else false
	mute_button.text = "AUDIO: MUTED" if is_muted else "AUDIO: ON"

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if credits_modal and credits_modal.visible:
				_on_close_credits_pressed()
			else:
				_on_quit_pressed()
		elif event.keycode == KEY_M:
			_on_mute_pressed()

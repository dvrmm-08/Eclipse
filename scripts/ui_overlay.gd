extends CanvasLayer

@onready var dimension_label: Label = $HUD/DimensionLabel
@onready var controls_label: Label = $HUD/ControlsLabel
@onready var message_box: PanelContainer = $HUD/MessageBox
@onready var message_label: Label = $HUD/MessageBox/MarginContainer/MessageLabel
@onready var level_banner: Label = $HUD/LevelBanner
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var message_timer: float = 0.0

func _init_ui() -> void:
	if not message_box and has_node("HUD/MessageBox"):
		message_box = $HUD/MessageBox
	if not message_label and has_node("HUD/MessageBox/MarginContainer/MessageLabel"):
		message_label = $HUD/MessageBox/MarginContainer/MessageLabel
	if not dimension_label and has_node("HUD/DimensionLabel"):
		dimension_label = $HUD/DimensionLabel
	if not controls_label and has_node("HUD/ControlsLabel"):
		controls_label = $HUD/ControlsLabel
	if not level_banner and has_node("HUD/LevelBanner"):
		level_banner = $HUD/LevelBanner
	if not canvas_modulate and has_node("CanvasModulate"):
		canvas_modulate = $CanvasModulate

func _ready() -> void:
	add_to_group("ui")
	_init_ui()
	if message_box:
		message_box.visible = false
	if level_banner:
		level_banner.visible = false
	if controls_label:
		controls_label.text = "WASD: Move | P: Switch Form | E: Interact | M: Mute | ESC: Menu | R: Restart"
	update_dimension(false)

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			hide_message()

func update_dimension(eclipse: bool) -> void:
	_init_ui()
	if not dimension_label:
		return
		
	if canvas_modulate:
		# Keep full clarity so pixel art textures shine cleanly without a blanket tint
		canvas_modulate.color = Color(1.0, 1.0, 1.0, 1.0)
		
	if eclipse:
		dimension_label.text = "● ECLIPSE MODE [Shadow Form]"
		dimension_label.modulate = Color(1.0, 0.35, 0.45, 1.0)
	else:
		dimension_label.text = "○ NORMAL WORLD [Wanderer]"
		dimension_label.modulate = Color(0.85, 0.95, 1.0, 1.0)

func show_message(text: String, duration: float = 6.0) -> void:
	_init_ui()
	if message_label:
		message_label.text = text
		message_label.set("theme_override_colors/font_color", Color(0.95, 0.95, 1, 1))
	_set_msg_border_color(Color(0.2, 0.8, 0.85, 0.85))
	if message_box:
		message_box.visible = true
		message_box.modulate.a = 1.0
	message_timer = duration

func hide_message() -> void:
	_init_ui()
	if message_box:
		message_box.visible = false
	message_timer = 0.0

func show_dialogue(speaker: String, text: String, duration: float = 4.0) -> void:
	_init_ui()
	if not message_box or not message_label:
		return

	if speaker != "":
		message_label.text = "%s: \"%s\"" % [speaker, text]
		if speaker == "Wanderer":
			message_label.set("theme_override_colors/font_color", Color(0.9, 0.98, 1.0, 1.0))
			_set_msg_border_color(Color(0.25, 0.85, 0.95, 0.95))
		elif speaker == "Shadow":
			message_label.set("theme_override_colors/font_color", Color(1.0, 0.88, 0.9, 1.0))
			_set_msg_border_color(Color(0.95, 0.25, 0.35, 0.95))
		else:
			message_label.set("theme_override_colors/font_color", Color(0.95, 0.95, 1.0, 1.0))
			_set_msg_border_color(Color(0.2, 0.8, 0.85, 0.85))
	else:
		message_label.text = "\"%s\"" % [text]
		message_label.set("theme_override_colors/font_color", Color(0.95, 0.95, 1.0, 1.0))
		_set_msg_border_color(Color(0.2, 0.8, 0.85, 0.85))

	message_box.visible = true
	message_box.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(message_box, "modulate:a", 1.0, 0.25)
	message_timer = duration

func hide_dialogue(fade_time: float = 0.3) -> void:
	_init_ui()
	if not message_box or not message_box.visible:
		return
	message_timer = 0.0
	var tw = create_tween()
	tw.tween_property(message_box, "modulate:a", 0.0, fade_time)
	tw.tween_callback(func():
		if message_box:
			message_box.visible = false
	)

func hide_hud() -> void:
	_init_ui()
	if dimension_label:
		dimension_label.visible = false
	if controls_label:
		controls_label.visible = false
	if level_banner:
		level_banner.visible = false

func _set_msg_border_color(color: Color) -> void:
	if message_box:
		var sb = message_box.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			sb.border_color = color

func show_ending_card() -> Control:
	_init_ui()
	hide_hud()
	hide_message()

	var ending_card = Control.new()
	ending_card.name = "EndingCard"
	ending_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_card.modulate.a = 0.0
	add_child(ending_card)

	# Fullscreen dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.025, 0.04, 1.0)
	ending_card.add_child(bg)

	# Centered column
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_card.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var font_press_start = load("res://assets/fonts/PressStart2P-Regular.ttf")
	var font_silkscreen = load("res://assets/fonts/Silkscreen-Regular.ttf")

	# Title: ECLIPSE
	var title_lbl = Label.new()
	title_lbl.text = "ECLIPSE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_press_start:
		title_lbl.add_theme_font_override("font", font_press_start)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.95, 0.2, 0.3, 0.6))
	title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title_lbl)

	# Tagline: Some shadows remember.
	var tagline_lbl = Label.new()
	tagline_lbl.text = "Some shadows remember."
	tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen:
		tagline_lbl.add_theme_font_override("font", font_silkscreen)
	tagline_lbl.add_theme_font_size_override("font_size", 12)
	tagline_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 0.95, 0.95))
	vbox.add_child(tagline_lbl)

	# Spacer
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sp1)

	# Subtitle: The End... for now.
	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "The End... for now."
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen:
		subtitle_lbl.add_theme_font_override("font", font_silkscreen)
	subtitle_lbl.add_theme_font_size_override("font_size", 11)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82, 0.9))
	vbox.add_child(subtitle_lbl)

	# Spacer
	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(sp2)

	# Return to Main Menu button
	var btn = Button.new()
	btn.name = "ReturnToMenuButton"
	btn.text = "Return to Main Menu"
	btn.custom_minimum_size = Vector2(240, 36)
	if font_press_start:
		btn.add_theme_font_override("font", font_press_start)
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.2, 0.88, 0.98, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(0.2, 0.88, 0.98, 1.0))

	# Normal style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.08, 0.13, 0.9)
	style_normal.border_color = Color(0.25, 0.45, 0.65, 0.8)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style_normal)

	# Hover style
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.09, 0.16, 0.25, 0.95)
	style_hover.border_color = Color(0.2, 0.85, 0.95, 1.0)
	style_hover.set_border_width_all(1)
	style_hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", style_hover)

	# Focus style
	var style_focus = StyleBoxFlat.new()
	style_focus.bg_color = Color(0.09, 0.16, 0.25, 0.95)
	style_focus.border_color = Color(0.2, 0.85, 0.95, 1.0)
	style_focus.set_border_width_all(2)
	style_focus.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("focus", style_focus)

	# Pressed style
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.2, 0.08, 0.14, 0.95)
	style_pressed.border_color = Color(0.95, 0.25, 0.35, 1.0)
	style_pressed.set_border_width_all(1)
	style_pressed.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.mouse_entered.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_hover"):
			audio_mgr.play_ui_hover()
	)

	btn.pressed.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_select"):
			audio_mgr.play_ui_select()
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	)

	vbox.add_child(btn)

	# Fade in ending card smoothly
	var tw = create_tween()
	tw.tween_property(ending_card, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		btn.grab_focus()
	)

	return ending_card

func show_banner(title: String, subtitle: String = "") -> void:
	_init_ui()
	if not level_banner:
		return
	level_banner.text = title if subtitle == "" else title + "\n" + subtitle
	level_banner.visible = true
	level_banner.modulate.a = 0.0
	
	if is_inside_tree() and get_tree():
		var tween = create_tween()
		tween.tween_property(level_banner, "modulate:a", 1.0, 0.4)
		tween.tween_interval(2.2)
		tween.tween_property(level_banner, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func(): level_banner.visible = false)
	else:
		level_banner.modulate.a = 1.0

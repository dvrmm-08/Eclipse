extends CanvasLayer

@onready var dimension_label: Label = $HUD/DimensionLabel
@onready var controls_label: Label = $HUD/ControlsLabel
@onready var music_button: Button = get_node_or_null("HUD/MusicToggleButton") as Button
@onready var message_box: PanelContainer = $HUD/MessageBox
@onready var message_label: Label = $HUD/MessageBox/MarginContainer/MessageLabel
@onready var level_banner: Label = $HUD/LevelBanner
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var message_timer: float = 0.0
var font_silkscreen: Font = null

func _init_ui() -> void:
	if not message_box and has_node("HUD/MessageBox"):
		message_box = $HUD/MessageBox
	if not message_label and has_node("HUD/MessageBox/MarginContainer/MessageLabel"):
		message_label = $HUD/MessageBox/MarginContainer/MessageLabel
	if not dimension_label and has_node("HUD/DimensionLabel"):
		dimension_label = $HUD/DimensionLabel
	if not controls_label and has_node("HUD/ControlsLabel"):
		controls_label = $HUD/ControlsLabel
	if not music_button and has_node("HUD/MusicToggleButton"):
		music_button = $HUD/MusicToggleButton
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
		controls_label.text = "WASD: Move | P: Switch | E: Interact | ESC: Menu"
	update_dimension(false)

	if font_silkscreen == null and ResourceLoader.exists("res://assets/fonts/Silkscreen-Regular.ttf"):
		font_silkscreen = load("res://assets/fonts/Silkscreen-Regular.ttf")

	if music_button:
		if not music_button.pressed.is_connected(_on_music_button_pressed):
			music_button.pressed.connect(_on_music_button_pressed)
		if not music_button.mouse_entered.is_connected(_on_music_button_hover):
			music_button.mouse_entered.connect(_on_music_button_hover)

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_signal("music_mute_toggled"):
		if not audio_mgr.music_mute_toggled.is_connected(_on_music_mute_toggled):
			audio_mgr.music_mute_toggled.connect(_on_music_mute_toggled)

	_update_music_button()

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
	if music_button:
		music_button.visible = false

func show_hud() -> void:
	_init_ui()
	if dimension_label:
		dimension_label.visible = true
	if controls_label:
		controls_label.visible = true
	if music_button:
		music_button.visible = true

func _on_music_button_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_ui_click"):
			audio_mgr.play_ui_click()
		if audio_mgr.has_method("toggle_music_mute"):
			audio_mgr.toggle_music_mute()
		else:
			audio_mgr.toggle_mute()
	_update_music_button()

func _on_music_button_hover() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_hover"):
		audio_mgr.play_ui_hover()

func _on_music_mute_toggled(_muted: bool) -> void:
	_update_music_button()

func _update_music_button() -> void:
	if not music_button:
		return
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var is_muted = audio_mgr.get_music_muted() if audio_mgr and audio_mgr.has_method("get_music_muted") else false
	_apply_music_button_style(is_muted)

func _apply_music_button_style(is_muted: bool) -> void:
	if not music_button:
		return

	if font_silkscreen:
		music_button.add_theme_font_override("font", font_silkscreen)
	music_button.add_theme_font_size_override("font_size", 8)

	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()

	for sb in [style_normal, style_hover, style_pressed]:
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)

	if is_muted:
		music_button.text = "MUSIC: OFF"
		music_button.tooltip_text = "Music: OFF (Click to unmute)"

		# Dark, muted colors
		style_normal.bg_color = Color(0.06, 0.07, 0.10, 0.85)
		style_normal.border_color = Color(0.32, 0.35, 0.42, 0.6)

		style_hover.bg_color = Color(0.10, 0.12, 0.18, 0.95)
		style_hover.border_color = Color(0.55, 0.60, 0.70, 0.9)

		style_pressed.bg_color = Color(0.14, 0.16, 0.22, 0.95)
		style_pressed.border_color = Color(0.70, 0.75, 0.85, 1.0)

		music_button.add_theme_color_override("font_color", Color(0.60, 0.64, 0.72, 0.8))
		music_button.add_theme_color_override("font_hover_color", Color(0.85, 0.88, 0.95, 1.0))
		music_button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		music_button.text = "MUSIC: ON"
		music_button.tooltip_text = "Music: ON (Click to mute)"

		# Radiant cyan theme matching Eclipse UI
		style_normal.bg_color = Color(0.05, 0.09, 0.15, 0.85)
		style_normal.border_color = Color(0.20, 0.70, 0.82, 0.65)

		style_hover.bg_color = Color(0.08, 0.15, 0.24, 0.95)
		style_hover.border_color = Color(0.30, 0.90, 1.0, 0.95)

		style_pressed.bg_color = Color(0.12, 0.20, 0.30, 0.95)
		style_pressed.border_color = Color(0.40, 1.0, 1.0, 1.0)

		music_button.add_theme_color_override("font_color", Color(0.20, 0.85, 0.95, 1.0))
		music_button.add_theme_color_override("font_hover_color", Color(0.50, 0.95, 1.0, 1.0))
		music_button.add_theme_color_override("font_pressed_color", Color(0.75, 1.0, 1.0, 1.0))

	music_button.add_theme_stylebox_override("normal", style_normal)
	music_button.add_theme_stylebox_override("hover", style_hover)
	music_button.add_theme_stylebox_override("pressed", style_pressed)
	music_button.add_theme_stylebox_override("focus", style_hover)

func _set_msg_border_color(color: Color) -> void:
	if message_box:
		var sb = message_box.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			sb.border_color = color

func _apply_gold_button_style(btn: Button) -> void:
	if not btn:
		return
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.06, 0.08, 0.14, 0.9)
	sb_norm.border_color = Color(0.75, 0.62, 0.25, 0.8) # Antique Gold
	sb_norm.set_border_width_all(1)
	sb_norm.set_corner_radius_all(2)
	sb_norm.set_content_margin_all(5)
	btn.add_theme_stylebox_override("normal", sb_norm)

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.12, 0.16, 0.26, 0.95)
	sb_hover.border_color = Color(0.98, 0.88, 0.45, 1.0) # Bright Gold
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(2)
	sb_hover.set_content_margin_all(5)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)

	var sb_press = StyleBoxFlat.new()
	sb_press.bg_color = Color(0.18, 0.14, 0.10, 0.95)
	sb_press.border_color = Color(0.20, 0.88, 0.98, 1.0) # Cyan accent
	sb_press.set_border_width_all(1)
	sb_press.set_corner_radius_all(2)
	sb_press.set_content_margin_all(5)
	btn.add_theme_stylebox_override("pressed", sb_press)

	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.65, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.35, 0.95, 1.0, 1.0))

	btn.mouse_entered.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_hover"):
			audio_mgr.play_ui_hover()
	)

func show_ending_card() -> Control:
	_init_ui()
	hide_hud()
	hide_message()

	var ending_card = Control.new()
	ending_card.name = "EndingCard"
	ending_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_card.modulate.a = 0.0
	add_child(ending_card)

	# Fullscreen midnight background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.035, 0.07, 1.0)
	ending_card.add_child(bg)

	var font_press_start = load("res://assets/fonts/PressStart2P-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/PressStart2P-Regular.ttf") else null
	var font_silkscreen = load("res://assets/fonts/Silkscreen-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/Silkscreen-Regular.ttf") else null

	# ── CONTAINER 1: Epilogue Story Passage Frame (Phase 1) ──
	var epilogue_center = CenterContainer.new()
	epilogue_center.name = "EpilogueCenter"
	epilogue_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_card.add_child(epilogue_center)

	var tome_panel = PanelContainer.new()
	tome_panel.custom_minimum_size = Vector2(570, 346)
	var sb_tome = StyleBoxFlat.new()
	sb_tome.bg_color = Color(0.045, 0.055, 0.1, 0.96)
	sb_tome.border_color = Color(0.83, 0.69, 0.22, 0.85) # Antique Gold
	sb_tome.set_border_width_all(2)
	sb_tome.set_corner_radius_all(3)
	sb_tome.shadow_color = Color(0, 0, 0, 0.8)
	sb_tome.shadow_size = 12
	tome_panel.add_theme_stylebox_override("panel", sb_tome)
	epilogue_center.add_child(tome_panel)

	var epilogue_vbox = VBoxContainer.new()
	epilogue_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	epilogue_vbox.add_theme_constant_override("separation", 5)
	tome_panel.add_child(epilogue_vbox)

	# Subtitle & Title
	var sub_lbl = Label.new()
	sub_lbl.text = "— CHRONICLE OF ECLIPSE —"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen: sub_lbl.add_theme_font_override("font", font_silkscreen)
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35, 0.9))
	epilogue_vbox.add_child(sub_lbl)

	var epi_title = Label.new()
	epi_title.text = "EPILOGUE : THE EDGE OF SHADOWS"
	epi_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_press_start: epi_title.add_theme_font_override("font", font_press_start)
	epi_title.add_theme_font_size_override("font_size", 10)
	epi_title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55, 1.0))
	epi_title.add_theme_color_override("font_shadow_color", Color(0.25, 0.18, 0.05, 0.8))
	epi_title.add_theme_constant_override("shadow_offset_x", 1)
	epi_title.add_theme_constant_override("shadow_offset_y", 1)
	epilogue_vbox.add_child(epi_title)

	var div1 = Label.new()
	div1.text = "◆ ────────────── ❖ ────────────── ◆"
	div1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen: div1.add_theme_font_override("font", font_silkscreen)
	div1.add_theme_font_size_override("font_size", 8)
	div1.add_theme_color_override("font_color", Color(0.72, 0.58, 0.22, 0.8))
	epilogue_vbox.add_child(div1)

	# Pixel art illustration
	var img_box = CenterContainer.new()
	epilogue_vbox.add_child(img_box)

	var img_frame = PanelContainer.new()
	var sb_img = StyleBoxFlat.new()
	sb_img.bg_color = Color(0.02, 0.03, 0.06, 1.0)
	sb_img.border_color = Color(0.75, 0.62, 0.22, 0.7)
	sb_img.set_border_width_all(1)
	sb_img.set_corner_radius_all(2)
	img_frame.add_theme_stylebox_override("panel", sb_img)
	img_box.add_child(img_frame)

	var img_tex = TextureRect.new()
	img_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img_tex.custom_minimum_size = Vector2(240, 120)
	img_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/story/ending_illustration.png"):
		img_tex.texture = load("res://assets/story/ending_illustration.png")
	img_frame.add_child(img_tex)

	# Story Passage Text Container
	var text_margin = MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 24)
	text_margin.add_theme_constant_override("margin_right", 24)
	epilogue_vbox.add_child(text_margin)

	var passage_label = Label.new()
	passage_label.custom_minimum_size = Vector2(490, 52)
	passage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	passage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_silkscreen: passage_label.add_theme_font_override("font", font_silkscreen)
	passage_label.add_theme_font_size_override("font_size", 10)
	passage_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92, 1.0))
	passage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	passage_label.add_theme_constant_override("shadow_offset_x", 1)
	passage_label.add_theme_constant_override("shadow_offset_y", 1)
	passage_label.add_theme_constant_override("line_spacing", 4)
	text_margin.add_child(passage_label)

	var div2 = Label.new()
	div2.text = "─── ◆ ───"
	div2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen: div2.add_theme_font_override("font", font_silkscreen)
	div2.add_theme_font_size_override("font_size", 8)
	div2.add_theme_color_override("font_color", Color(0.72, 0.58, 0.22, 0.75))
	epilogue_vbox.add_child(div2)

	# Navigation button for passage
	var nav_hbox = HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	epilogue_vbox.add_child(nav_hbox)

	var advance_passage_btn = Button.new()
	advance_passage_btn.name = "AdvancePassageButton"
	advance_passage_btn.text = "[ NEXT ► ]"
	advance_passage_btn.custom_minimum_size = Vector2(140, 24)
	if font_silkscreen: advance_passage_btn.add_theme_font_override("font", font_silkscreen)
	advance_passage_btn.add_theme_font_size_override("font_size", 9)
	advance_passage_btn.focus_mode = Control.FOCUS_NONE
	advance_passage_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_gold_button_style(advance_passage_btn)
	nav_hbox.add_child(advance_passage_btn)

	# ── CONTAINER 2: Final Title Card & Eclipse (Phase 2) ──
	var title_card_center = CenterContainer.new()
	title_card_center.name = "TitleCardCenter"
	title_card_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_card_center.visible = false
	title_card_center.modulate.a = 0.0
	ending_card.add_child(title_card_center)

	var card_vbox = VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 12)
	title_card_center.add_child(card_vbox)

	# Eclipse Emblem with animated breathing corona pulse
	var eclipse_rect = TextureRect.new()
	eclipse_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	eclipse_rect.custom_minimum_size = Vector2(64, 64)
	eclipse_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	eclipse_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/story/eclipse_disc.png"):
		eclipse_rect.texture = load("res://assets/story/eclipse_disc.png")
	var eclipse_container = CenterContainer.new()
	eclipse_container.add_child(eclipse_rect)
	card_vbox.add_child(eclipse_container)

	# Subtle pulse tween for eclipse
	var pulse_tw = create_tween().set_loops()
	pulse_tw.tween_property(eclipse_rect, "modulate", Color(1.3, 0.7, 0.7, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	pulse_tw.tween_property(eclipse_rect, "modulate", Color(1.0, 1.0, 1.0, 0.95), 1.6).set_trans(Tween.TRANS_SINE)

	# Title: ECLIPSE
	var main_title = Label.new()
	main_title.text = "ECLIPSE"
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_press_start: main_title.add_theme_font_override("font", font_press_start)
	main_title.add_theme_font_size_override("font_size", 24)
	main_title.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	main_title.add_theme_color_override("font_shadow_color", Color(0.85, 0.15, 0.25, 0.95))
	main_title.add_theme_constant_override("shadow_offset_x", 2)
	main_title.add_theme_constant_override("shadow_offset_y", 2)
	card_vbox.add_child(main_title)

	# Subtitle: THE JOURNEY CONTINUES
	var cont_lbl = Label.new()
	cont_lbl.text = "THE JOURNEY CONTINUES"
	cont_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_press_start: cont_lbl.add_theme_font_override("font", font_press_start)
	cont_lbl.add_theme_font_size_override("font_size", 11)
	cont_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55, 1.0)) # Antique Gold
	card_vbox.add_child(cont_lbl)

	var div3 = Label.new()
	div3.text = "◆ ────────────── ❖ ────────────── ◆"
	div3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen: div3.add_theme_font_override("font", font_silkscreen)
	div3.add_theme_font_size_override("font_size", 8)
	div3.add_theme_color_override("font_color", Color(0.72, 0.58, 0.22, 0.8))
	card_vbox.add_child(div3)

	# Tagline: "The next chapter is in development."
	var next_ch_lbl = Label.new()
	next_ch_lbl.text = "\"The next chapter is in development.\""
	next_ch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_silkscreen: next_ch_lbl.add_theme_font_override("font", font_silkscreen)
	next_ch_lbl.add_theme_font_size_override("font_size", 10)
	next_ch_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.9))
	card_vbox.add_child(next_ch_lbl)

	# Spacer
	var sp_card = Control.new()
	sp_card.custom_minimum_size = Vector2(0, 10)
	card_vbox.add_child(sp_card)

	# Return to Main Menu button
	var btn = Button.new()
	btn.name = "ReturnToMenuButton"
	btn.text = "RETURN TO MAIN MENU"
	btn.custom_minimum_size = Vector2(230, 32)
	if font_press_start: btn.add_theme_font_override("font", font_press_start)
	btn.add_theme_font_size_override("font_size", 8)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_gold_button_style(btn)
	card_vbox.add_child(btn)

	btn.pressed.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_select"):
			audio_mgr.play_ui_select()
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	)

	# ── PASSAGE SEQUENCING LOGIC ──
	var p1_text = "The Wanderer reaches the end of the ruins.\n\nThe Watchers fall silent.\n\nFor the first time, the Shadow does not disappear when the Wanderer turns toward it.\n\nIt simply stands there, waiting."
	var p2_text = "You have found your way out.\n\nBut have you found your way back?"

	passage_label.text = p1_text
	var passage_step = [1] # Mutable state in closure

	var fn_show_passage2 = func():
		passage_step[0] = 2
		advance_passage_btn.text = "[ CONTINUE ► ]"
		var p_tw = create_tween()
		p_tw.tween_property(passage_label, "modulate:a", 0.0, 0.15)
		p_tw.tween_callback(func():
			passage_label.text = p2_text
		)
		p_tw.tween_property(passage_label, "modulate:a", 1.0, 0.25)

	var fn_show_final_card = func():
		passage_step[0] = 3
		var c_tw = create_tween()
		c_tw.tween_property(epilogue_center, "modulate:a", 0.0, 0.4)
		c_tw.tween_callback(func():
			epilogue_center.visible = false
			title_card_center.visible = true
		)
		c_tw.tween_property(title_card_center, "modulate:a", 1.0, 0.6)
		c_tw.tween_callback(func():
			btn.grab_focus()
		)

	advance_passage_btn.pressed.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_click"):
			audio_mgr.play_ui_click()

		if passage_step[0] == 1:
			fn_show_passage2.call()
		elif passage_step[0] == 2:
			fn_show_final_card.call()
	)

	# Fade in ending card smoothly
	var tw = create_tween()
	tw.tween_property(ending_card, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

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

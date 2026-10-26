extends Control

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Story Introduction Controller (Retro Fantasy Legend)
# 
# Presents an ancient framed chronicle across 4 illuminated pages with:
#   - Deep midnight sky background with shimmering stars.
#   - Antique gold pixel borders with ornamental corner filigrees.
#   - Authentic 8-bit/16-bit pixel-art vignettes.
#   - Large chunky headings (Press Start 2P) and ivory body text (Silkscreen).
#   - Retro NEXT, BACK, and SKIP navigation with keyboard support (Enter/Space/Esc).
#   - Seamless transition into Level 1.
# ═════════════════════════════════════════════════════════════════════════════

const FIRST_LEVEL_PATH: String = "res://scenes/level_1.tscn"

const PAGES = [
	{
		"roman": "PAGE I",
		"title": "PAGE I : BEFORE THE ECLIPSE",
		"text": "Once, the world existed in two reflections.\n\nOne held everything we chose to remember.\nThe other held everything we tried to forget.",
		"image": "res://assets/story/intro_page1.png"
	},
	{
		"roman": "PAGE II",
		"title": "PAGE II : THE FIRST ECLIPSE",
		"text": "But forgotten things do not simply disappear.\n\nAnd when the boundary between the two worlds began to break, something was left behind.",
		"image": "res://assets/story/intro_page2.png"
	},
	{
		"roman": "PAGE III",
		"title": "PAGE III : THE WANDERER",
		"text": "You awaken in a world you do not recognise.\n\nYou remember nothing of how you arrived.\n\nOnly the feeling that something is waiting for you.",
		"image": "res://assets/story/intro_page3.png"
	},
	{
		"roman": "PAGE IV",
		"title": "PAGE IV : THE OTHER SIDE",
		"text": "Somewhere beyond what you can see, a familiar shadow follows.\n\nIt knows your name.\n\nYou do not.",
		"image": "res://assets/story/intro_page4.png"
	}
]

var current_page_index: int = 0
var is_transitioning: bool = false
var _stars: Array = []
var _star_time: float = 0.0

@onready var page_title_label: Label = $FrameContainer/TomePanel/VBoxContainer/HeaderContainer/PageTitleLabel
@onready var illustration_texture: TextureRect = $FrameContainer/TomePanel/VBoxContainer/IllustrationBox/IllustrationFrame/IllustrationTexture
@onready var story_text_label: Label = $FrameContainer/TomePanel/VBoxContainer/StoryTextContainer/StoryTextLabel
@onready var page_dots_label: Label = $FrameContainer/TomePanel/VBoxContainer/NavigationHBox/PageDotsLabel
@onready var back_button: Button = $FrameContainer/TomePanel/VBoxContainer/NavigationHBox/BackButton
@onready var next_button: Button = $FrameContainer/TomePanel/VBoxContainer/NavigationHBox/NextButton
@onready var skip_button: Button = $FrameContainer/TomePanel/SkipButton
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var starfield: Control = $Starfield
@onready var page_content_node: Control = $FrameContainer/TomePanel/VBoxContainer

func _ready() -> void:
	# Ensure audio plays menu/prologue music
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_menu_music"):
		audio_mgr.play_menu_music()

	_init_starfield()
	if starfield:
		starfield.draw.connect(_draw_starfield_custom)
	_apply_button_styles()

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.mouse_entered.connect(_on_button_hover)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		next_button.mouse_entered.connect(_on_button_hover)
		next_button.grab_focus()
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
		skip_button.mouse_entered.connect(_on_button_hover)

	# Smooth entrance from black
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate = Color(0, 0, 0, 1.0)
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.6)

	show_page(0, false)

func _init_starfield() -> void:
	_stars.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(50):
		var x = rng.randf_range(8.0, 632.0)
		var y = rng.randf_range(8.0, 376.0)
		var speed = rng.randf_range(1.5, 3.5)
		var phase = rng.randf_range(0.0, TAU)
		var color_type = rng.randi_range(0, 2) # white, gold, cyan
		_stars.append({"pos": Vector2(x, y), "speed": speed, "phase": phase, "type": color_type})

func _process(delta: float) -> void:
	_star_time += delta
	if starfield:
		starfield.queue_redraw()

func _draw_starfield_custom() -> void:
	if not starfield:
		return
	for s in _stars:
		var brightness = 0.4 + 0.6 * (0.5 + 0.5 * sin(_star_time * s["speed"] + s["phase"]))
		var c: Color
		if s["type"] == 0:
			c = Color(1.0, 1.0, 1.0, brightness)
		elif s["type"] == 1:
			c = Color(0.98, 0.85, 0.45, brightness)
		else:
			c = Color(0.45, 0.90, 1.0, brightness)
		starfield.draw_rect(Rect2(s["pos"], Vector2(2, 2)), c)

func show_page(index: int, animate: bool = true) -> void:
	if index < 0 or index >= PAGES.size():
		return
	current_page_index = index
	var page_data = PAGES[index]
	_apply_page_content(page_data, index)

	if animate and page_content_node:
		page_content_node.modulate.a = 0.2
		var tw = create_tween()
		tw.tween_property(page_content_node, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)

func _apply_page_content(page_data: Dictionary, index: int) -> void:
	if page_title_label:
		page_title_label.text = page_data["title"]
	if story_text_label:
		story_text_label.text = page_data["text"]
	if illustration_texture:
		var img_path = page_data["image"]
		if ResourceLoader.exists(img_path):
			illustration_texture.texture = load(img_path)

	# Update page counter dots
	if page_dots_label:
		var indicators = []
		for i in range(PAGES.size()):
			indicators.append("●" if i == index else "○")
		page_dots_label.text = "[ %s / IV ]  %s" % [PAGES[index]["roman"].replace("PAGE ", ""), " ".join(indicators)]

	# Update Back & Next buttons
	if back_button:
		back_button.disabled = (index == 0)
		back_button.modulate.a = 0.4 if (index == 0) else 1.0

	if next_button:
		if index == PAGES.size() - 1:
			next_button.text = "[ BEGIN JOURNEY ► ]"
		else:
			next_button.text = "[ NEXT ► ]"

func _on_next_pressed() -> void:
	if is_transitioning:
		return
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_click"):
		audio_mgr.play_ui_click()

	if current_page_index < PAGES.size() - 1:
		show_page(current_page_index + 1, true)
	else:
		start_game()

func _on_back_pressed() -> void:
	if is_transitioning or current_page_index <= 0:
		return
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_back"):
		audio_mgr.play_ui_back()
	show_page(current_page_index - 1, true)

func _on_skip_pressed() -> void:
	if is_transitioning:
		return
	skip_intro()

func skip_intro() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_select"):
		audio_mgr.play_ui_select()
	start_game()

func start_game() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("fade_out_music"):
		audio_mgr.fade_out_music(0.3)

	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate = Color(0, 0, 0, 0)
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.25)
		await tw.finished

	if ResourceLoader.exists(FIRST_LEVEL_PATH):
		get_tree().change_scene_to_file(FIRST_LEVEL_PATH)
	else:
		push_error("First level not found: " + FIRST_LEVEL_PATH)

func _on_button_hover() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_ui_hover"):
		audio_mgr.play_ui_hover()

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			skip_intro()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_RIGHT:
			_on_next_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT:
			_on_back_pressed()
			get_viewport().set_input_as_handled()

func _apply_button_styles() -> void:
	var font_silkscreen = load("res://assets/fonts/Silkscreen-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/Silkscreen-Regular.ttf") else null
	var buttons = [back_button, next_button, skip_button]

	for btn in buttons:
		if not btn:
			continue
		if font_silkscreen:
			btn.add_theme_font_override("font", font_silkscreen)
		btn.add_theme_font_size_override("font_size", 9)
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Normal style
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = Color(0.06, 0.08, 0.14, 0.9)
		sb_norm.border_color = Color(0.75, 0.62, 0.25, 0.8) # Antique Gold border
		sb_norm.set_border_width_all(1)
		sb_norm.set_corner_radius_all(2)
		sb_norm.set_content_margin_all(5)
		btn.add_theme_stylebox_override("normal", sb_norm)

		# Hover style
		var sb_hover = StyleBoxFlat.new()
		sb_hover.bg_color = Color(0.12, 0.16, 0.26, 0.95)
		sb_hover.border_color = Color(0.98, 0.88, 0.45, 1.0) # Bright gold border
		sb_hover.set_border_width_all(1)
		sb_hover.set_corner_radius_all(2)
		sb_hover.set_content_margin_all(5)
		btn.add_theme_stylebox_override("hover", sb_hover)
		btn.add_theme_stylebox_override("focus", sb_hover)

		# Pressed style
		var sb_press = StyleBoxFlat.new()
		sb_press.bg_color = Color(0.18, 0.14, 0.10, 0.95)
		sb_press.border_color = Color(0.20, 0.88, 0.98, 1.0) # Cyan flash
		sb_press.set_border_width_all(1)
		sb_press.set_corner_radius_all(2)
		sb_press.set_content_margin_all(5)
		btn.add_theme_stylebox_override("pressed", sb_press)

		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.35, 0.95, 1.0, 1.0))

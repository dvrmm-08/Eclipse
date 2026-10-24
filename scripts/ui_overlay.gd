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
	if message_box:
		message_box.visible = true
	message_timer = duration

func hide_message() -> void:
	_init_ui()
	if message_box:
		message_box.visible = false
	message_timer = 0.0

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

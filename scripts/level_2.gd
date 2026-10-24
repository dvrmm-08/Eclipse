extends "res://scripts/level_base.gd"

const MAP_LAYOUT: Array[String] = [
	"####################", # 0
	"#...::...S...::...G#", # 1 Statue S at (9, 1), Gate G at (18, 1)
	"#...::...:...::....#", # 2
	"#...::::.:.::::....#", # 3 Walkway crossing laser line
	"#,::~~~~.~~~~:::...#", # 4 Shield spot at (9, 4)
	"#,::~===.===~:::L..#", # 5 Cyan Bridge (4..8, 10..14), Lever at (16, 5)
	"#,::~===.===~:::...#", # 6 Cyan Bridge
	"#,::~~~~.~~~~:::...#", # 7
	"#,::.T::::::::::...#", # 8 Tablet T at (5, 8)
	"#,,,,:::::::::::...#", # 9
	"#,,,,:::::::::::...#", # 10
	"####################"  # 11
]

@onready var gate: Area2D = $Objects/Gate
@onready var lever: Area2D = $Objects/Lever
@onready var tablet: Area2D = $Objects/Tablet
@onready var statue: StaticBody2D = $Objects/LaserStatue

var betrayal_triggered: bool = false

func _ready() -> void:
	level_title = "LEVEL 2"
	level_subtitle = "THE SHIELD OF FLESH"
	next_level_path = "res://scenes/level_3.tscn"
	
	super._ready()
	
	if grid:
		grid.build_map(MAP_LAYOUT)
		
	_setup_objects()

func _setup_objects() -> void:
	gate.position = Vector2(592, 48)
	gate.type = 3 # GATE
	gate.is_active = false
	
	lever.position = Vector2(528, 176)
	lever.type = 2 # LEVER
	lever.is_active = false
	lever.target_gate = gate
	if not lever.state_changed.is_connected(_on_lever_pulled):
		lever.state_changed.connect(_on_lever_pulled)
	
	tablet.position = Vector2(176, 272)
	tablet.type = 0 # TABLET
	tablet.message = "\"The void's gaze sears the naked soul. Let your flesh bear the stare.\""
	
	statue.position = Vector2(304, 48)
	statue.cast_direction = Vector2.DOWN
	statue.max_distance = 360.0
	
	wanderer.position = Vector2(112, 272)
	shadow.position = wanderer.position
	camera.position = wanderer.position

func _on_lever_pulled(active: bool) -> void:
	pass

func toggle_dimension() -> void:
	super.toggle_dimension()
	
	if lever.is_active and not eclipse_active and not betrayal_triggered:
		_trigger_first_betrayal()

func _trigger_first_betrayal() -> void:
	betrayal_triggered = true
	can_switch = false
	
	if is_inside_tree() and get_tree():
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			var dir_to_wanderer = (wanderer.global_position - shadow.global_position).normalized()
			if shadow.get_node_or_null("Sprite2D"):
				shadow.get_node("Sprite2D").flip_h = (dir_to_wanderer.x < 0)
				
			var step_tween = create_tween()
			step_tween.tween_property(shadow, "global_position", shadow.global_position + dir_to_wanderer * 24.0, 0.6)
			step_tween.tween_callback(func():
				if ui and ui.has_method("show_message"):
					ui.show_message("...The shadow moved on its own. It refuses to return.", 4.0)
				can_switch = true
			)
		)
	else:
		can_switch = true

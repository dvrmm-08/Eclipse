extends "res://scripts/level_base.gd"

const MAP_LAYOUT: Array[String] = [
	"####################", # 0
	"#...S...:...S...::.G#", # 1 Statue 1 at (4, 1), Statue 2 at (12, 1), Gate at (18, 1)
	"#...:...:...:...::..#", # 2
	"#..::::.:::::....:..#", # 3 Walkway connecting X=4 and X=12
	"#,::~~~~.~~~~.~~~:::..#", # 4
	"#,::~===.===~.==~::L..#", # 5 Cyan Bridge, Lever at (17, 5)
	"#,::~===.===~.==~:::..#", # 6
	"#,::~~~~.~~~~.~~~:::..#", # 7
	"#,::.T::::::::::::::..#", # 8 Tablet at (5, 8)
	"#,,,,:::::::::::::::..#", # 9
	"#,,,,:::::::::::::::..#", # 10
	"####################"  # 11
]

@onready var gate: Area2D = $Objects/Gate
@onready var lever: Area2D = $Objects/Lever
@onready var tablet: Area2D = $Objects/Tablet
@onready var statue1: StaticBody2D = $Objects/LaserStatue1
@onready var statue2: StaticBody2D = $Objects/LaserStatue2

var chase_active: bool = false
var chase_speed: float = 85.0

func _ready() -> void:
	level_title = "LEVEL 3"
	level_subtitle = "BETRAYAL"
	next_level_path = "res://scenes/ending.tscn"
	
	super._ready()
	
	if grid:
		grid.build_map(MAP_LAYOUT)
		
	_setup_objects()

func _setup_objects() -> void:
	# Gate at (18, 1) -> (592, 48)
	gate.position = Vector2(592, 48)
	gate.type = 3 # GATE
	gate.is_active = false
	
	# Lever at (17, 5) -> (560, 176)
	lever.position = Vector2(560, 176)
	lever.type = 2 # LEVER
	lever.is_active = false
	lever.target_gate = gate
	if not lever.state_changed.is_connected(_on_final_mechanism):
		lever.state_changed.connect(_on_final_mechanism)
	
	# Tablet at (5, 8) -> (176, 272)
	tablet.position = Vector2(176, 272)
	tablet.type = 0 # TABLET
	tablet.message = "\"Two gazes guard the final seal. The flesh must move between the shadows to let the unseen pass.\""
	
	# Statue 1 at (4, 1) -> (144, 48)
	statue1.position = Vector2(144, 48)
	statue1.cast_direction = Vector2.DOWN
	statue1.max_distance = 360.0
	
	# Statue 2 at (12, 1) -> (400, 48)
	statue2.position = Vector2(400, 48)
	statue2.cast_direction = Vector2.DOWN
	statue2.max_distance = 360.0
	
	wanderer.position = Vector2(80, 272)
	shadow.position = wanderer.position
	camera.position = wanderer.position

func _on_final_mechanism(active: bool) -> void:
	if active and not chase_active:
		_start_chase()

func _start_chase() -> void:
	chase_active = true
	can_switch = false # Cannot switch forms during chase
	
	# Force control back to Wanderer
	eclipse_active = false
	wanderer.is_controlled = true
	shadow.is_controlled = false
	if grid:
		grid.set_eclipse_mode(false)
	if ui:
		ui.update_dimension(false)
		ui.show_banner("RUN TO THE EXIT", "The shadow has broken free!")
		if ui.has_method("show_message"):
			ui.show_message("THE SHADOW IS HUNTING YOU. REACH THE EXIT GATE!")

func _physics_process(delta: float) -> void:
	super._process(delta)
	
	if chase_active and not is_completing:
		# Shadow stalks Wanderer!
		var dir = (wanderer.global_position - shadow.global_position).normalized()
		shadow.velocity = dir * chase_speed
		shadow.move_and_slide()
		
		# Facing
		if shadow.get_node_or_null("Sprite2D"):
			if dir.x < -0.1:
				shadow.get_node("Sprite2D").flip_h = true
			elif dir.x > 0.1:
				shadow.get_node("Sprite2D").flip_h = false
				
		# If shadow touches Wanderer during chase: reset to safe distance
		if shadow.global_position.distance_to(wanderer.global_position) < 18.0:
			_on_caught_by_shadow()

func _on_caught_by_shadow() -> void:
	# Stun/pushback effect, don't permakill
	shadow.global_position = wanderer.global_position - (wanderer.global_position - shadow.global_position).normalized() * 120.0
	if ui and ui.has_method("show_message"):
		ui.show_message("Cold hands brush your soul! Keep running!", 2.5)

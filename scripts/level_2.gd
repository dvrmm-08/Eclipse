extends "res://scripts/level_base.gd"

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2 — BLIND SPOT / THE SHIELD OF FLESH
#
# Mechanics:
#   - Two Watcher Statues with line-of-sight detection
#   - One physical timed red laser (cycling + blockable by Wanderer's body)
#   - Discoverable blind spot behind obstacles
#   - Editable cyan bridge across the void in Eclipse mode
#   - Mechanism (Lever) unlocking the Exit Gate
#   - Scripted First Betrayal sequence before transitioning to Level 3
# ═════════════════════════════════════════════════════════════════════════════

@onready var gate: Area2D = get_node_or_null("Objects/Gate")
@onready var lever: Area2D = get_node_or_null("Objects/Lever")
@onready var tablet: Area2D = get_node_or_null("Objects/Tablet")
@onready var exit_door: Area2D = get_node_or_null("Objects/Exit")
@onready var laser_statue: StaticBody2D = get_node_or_null("Objects/LaserStatue")
@onready var watcher_1: StaticBody2D = get_node_or_null("Objects/WatcherStatue1")
@onready var watcher_2: StaticBody2D = get_node_or_null("Objects/WatcherStatue2")

var betrayal_triggered: bool = false

func _ready() -> void:
	level_title = "LEVEL 2"
	level_subtitle = "BLIND SPOT"
	next_level_path = "res://scenes/level_3.tscn"

	super._ready()

	# Connect lever to gate if not set in scene
	if lever and gate and not lever.target_gate:
		lever.target_gate = gate

	if lever and not lever.state_changed.is_connected(_on_lever_pulled):
		lever.state_changed.connect(_on_lever_pulled)

	# Fixed camera centers on 640x384 room
	if camera:
		camera.global_position = Vector2(320, 192)

func _on_lever_pulled(active: bool) -> void:
	if active and ui and ui.has_method("show_message"):
		ui.show_message("The heavy iron gate clicked open.", 2.5)

func toggle_dimension() -> void:
	super.toggle_dimension()

	# Check for first betrayal trigger when lever is active and player returns to Wanderer
	if lever and lever.is_active and not eclipse_active and not betrayal_triggered:
		_trigger_first_betrayal()

func _trigger_first_betrayal() -> void:
	betrayal_triggered = true
	can_switch = false

	if is_inside_tree() and get_tree():
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			if not shadow or not wanderer:
				can_switch = true
				return

			# Show shadow taking an independent step toward wanderer
			shadow.visible = true
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

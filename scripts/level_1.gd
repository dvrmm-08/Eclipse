extends "res://scripts/level_base.gd"

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 1 — AWAKENING
# Discover the Other Dimension
#
# Fully editable in Godot's 2D Editor:
#   - Terrain painted across Ground, Walls, Void, EclipsePaths, Decoration
#   - Props (Trees, Bushes, Rocks) and Objects (Gate, Lever, Tablet, Note)
#     are independently placed and editable in the 2D viewport.
#   - No runtime procedural wiping or hardcoded map overrides!
# ═════════════════════════════════════════════════════════════════════════════

@onready var gate: Area2D = get_node_or_null("Objects/Gate")
@onready var lever: Area2D = get_node_or_null("Objects/Lever")
@onready var tablet: Area2D = get_node_or_null("Objects/Tablet")
@onready var note: Area2D = get_node_or_null("Objects/Note")

func _ready() -> void:
	level_title = "LEVEL 1"
	level_subtitle = "AWAKENING"
	next_level_path = "res://scenes/level_2.tscn"

	super._ready()

	# Connect lever to gate if not already wired in scene inspector
	if lever and gate and not lever.target_gate:
		lever.target_gate = gate

	# Fixed camera centers on the 640x384 room
	if camera:
		camera.global_position = Vector2(320, 192)

extends Node2D

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Level Grid System
# Controls the editable TileMapLayers:
#   - Ground: Walkable grass, dirt, stone floor (No collision)
#   - Walls: Solid stone masonry (Physics Layer 0 = Layer 1 Solid_Walls)
#   - Void: Deep chasm (Physics Layer 1 = Layer 18: Blocks Wanderer & Shadow)
#   - EclipsePaths: Hidden cyan bridge (Physics Layer 2 = Layer 2: Blocks Wanderer,
#                   walkable by Shadow)
#   - Decoration: Scenic floor details
# ═════════════════════════════════════════════════════════════════════════════

@onready var ground_layer: TileMapLayer = get_node_or_null("Ground")
@onready var walls_layer: TileMapLayer = get_node_or_null("Walls")
@onready var void_layer: TileMapLayer = get_node_or_null("Void")
@onready var eclipse_paths_layer: TileMapLayer = get_node_or_null("EclipsePaths")
@onready var decoration_layer: TileMapLayer = get_node_or_null("Decoration")

var _bridge_cells: Array[Vector2i] = []

func _ready() -> void:
	_get_layers()
	_setup_layers()
	set_eclipse_mode(false)

func _get_layers() -> void:
	if not void_layer and has_node("Void"):
		void_layer = $Void
	if not eclipse_paths_layer and has_node("EclipsePaths"):
		eclipse_paths_layer = $EclipsePaths
	if not ground_layer and has_node("Ground"):
		ground_layer = $Ground
	if not walls_layer and has_node("Walls"):
		walls_layer = $Walls
	if not decoration_layer and has_node("Decoration"):
		decoration_layer = $Decoration

func _setup_layers() -> void:
	# Ensure physics collision is enabled on the layers that need collision
	if void_layer:
		void_layer.collision_enabled = true
	if walls_layer:
		walls_layer.collision_enabled = true
	if eclipse_paths_layer:
		eclipse_paths_layer.collision_enabled = true

		# Record bridge cells authored by the designer
		_bridge_cells = eclipse_paths_layer.get_used_cells()

		# Ensure void layer does not place solid void barrier (Layer 18)
		# under the bridge, so the Shadow can walk on the bridge (Layer 2)
		if void_layer:
			for cell in _bridge_cells:
				void_layer.erase_cell(cell)

func set_eclipse_mode(active: bool) -> void:
	_get_layers()

	# 1. Reveal or hide the glowing cyan bridge
	# When hidden (Normal mode), collision on Layer 2 remains active, blocking the Wanderer.
	# When visible (Eclipse mode), Shadow (whose mask ignores Layer 2) walks across.
	if eclipse_paths_layer:
		eclipse_paths_layer.visible = active

	# 2. Swap Void tiles between near-black (2, 1) and glowing crimson (3, 1)
	if void_layer:
		var target_coords = Vector2i(3, 1) if active else Vector2i(2, 1)
		for cell in void_layer.get_used_cells():
			void_layer.set_cell(cell, 0, target_coords)

	# 3. Darken or restore ground & walls for Eclipse dimension atmosphere
	var terrain_tint = Color(0.42, 0.42, 0.52, 1.0) if active else Color(1.0, 1.0, 1.0, 1.0)
	if ground_layer:
		ground_layer.modulate = terrain_tint
	if walls_layer:
		walls_layer.modulate = terrain_tint
	if decoration_layer:
		decoration_layer.modulate = terrain_tint

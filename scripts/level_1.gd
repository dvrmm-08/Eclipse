extends "res://scripts/level_base.gd"

# ═════════════════════════════════════════════════════════════════════════════
# Level 1 — AWAKENING
# ═════════════════════════════════════════════════════════════════════════════
# An overgrown ruin.  The Wanderer wakes on a grassy stone platform (bottom-
# left).  A deep void chasm cuts the room in half.  To cross it the player
# must press P to summon the Shadow, walk the Shadow across a hidden cyan
# bridge to a lever on the far side, pull the lever, then return to the
# Wanderer and walk through the now-opened gate in the upper area.
#
# MAP KEY (see level_grid.gd):
#   #  Mossy stone wall           ,  Grass
#   :  Dirt path                  .  Stone floor
#   ~  Deep void chasm            =  Hidden cyan bridge (looks like void)
#   P  Stone pillar               (space) = open void same as ~
#   T  Tablet position (stone floor spawned under it)
#   L  Lever  position (stone floor spawned under it)
#   G  Gate   position (stone floor spawned under it)
#   N  Note   position (grass spawned under it)
# ═════════════════════════════════════════════════════════════════════════════

const MAP_LAYOUT: Array[String] = [
	"####################", # row 0   — top wall
	"#,,,,,,,,G,,,,,,,,:#", # row 1   — gate exit (col 9)
	"#,,,,::..:..:::::,:#", # row 2   — stone corridor behind gate
	"#,,,,::..:..:::::,:#", # row 3
	"#,,,,::..:..::L::,:#", # row 4   — lever on stone platform (col 13)
	"#,,,,::~~===~~:::,:#", # row 5   — void chasm + hidden bridge (cols 8-10)
	"#,,,,::~~~~~~::::,:#", # row 6   — void continues
	"#,,,,::~~~~~~::::,:#", # row 7   — void continues
	"#,,,T::~~===~~,,,,,#", # row 8   — tablet (col 4), second bridge
	"#,,,,::,,,,,,,,,,,,#", # row 9   — grass clearing
	"#,N,,::,,,,,,,,,,,,#", # row 10  — note side path (col 2)
	"####################", # row 11  — bottom wall
]

# Vegetation / decoration textures
const TEX_TREE = preload("res://assets/environment/vegetation/tree.png")
const TEX_BUSH = preload("res://assets/environment/vegetation/bush.png")
const TEX_ROCK = preload("res://assets/environment/props/rock_moss.png")

@onready var gate: Area2D = $Objects/Gate
@onready var lever: Area2D = $Objects/Lever
@onready var tablet: Area2D = $Objects/Tablet
@onready var note: Area2D = $Objects/Note

func _ready() -> void:
	level_title = "LEVEL 1"
	level_subtitle = "AWAKENING"
	next_level_path = "res://scenes/level_2.tscn"

	super._ready()

	# Build the tile grid
	if grid:
		grid.build_map(MAP_LAYOUT)

	# Position interactables and characters
	_setup_objects()

	# Add scenic decoration
	_add_decorations()

	# Fixed camera — show entire 640×384 room
	if camera:
		camera.global_position = Vector2(320, 192)

func _setup_objects() -> void:
	# Helper: grid (col,row) → world pixel center
	# world_x = col*32 + 16, world_y = row*32 + 16

	# Gate at col 9, row 1 → (304, 48)
	if gate:
		gate.position = Vector2(9 * 32 + 16, 1 * 32 + 16)
		gate.type = 3 # Type.GATE
		gate.is_active = false

	# Lever at col 13, row 4 → (432, 144)
	if lever:
		lever.position = Vector2(13 * 32 + 16, 4 * 32 + 16)
		lever.type = 2 # Type.LEVER
		lever.is_active = false
		lever.target_gate = gate

	# Tablet at col 4, row 8 → (144, 272)
	if tablet:
		tablet.position = Vector2(4 * 32 + 16, 8 * 32 + 16)
		tablet.type = 0 # Type.TABLET
		tablet.message = "\"The darkness hides the way. Press P to find the bridge.\""

	# Note at col 2, row 10 → (80, 336)
	if note:
		note.position = Vector2(2 * 32 + 16, 10 * 32 + 16)
		note.type = 1 # Type.NOTE
		note.message = "\"Your shadow remembers what you cannot see.\""

	# ── Character starting positions ──
	# Wanderer starts on the grass near the tablet — col 3, row 9 → (112, 304)
	if wanderer:
		wanderer.position = Vector2(3 * 32 + 16, 9 * 32 + 16)
	if shadow:
		shadow.position = wanderer.position

func _add_decorations() -> void:
	# Place trees, bushes, and mossy rocks as visual decoration.
	# These are pure Sprite2D — no collision (they sit on top of wall tiles
	# which already block movement).

	var decorations: Array[Dictionary] = [
		# Trees along the top — behind the wall, visible canopy peeking over
		{"tex": TEX_TREE, "pos": Vector2(2 * 32 + 16, 0 * 32 - 8)},
		{"tex": TEX_TREE, "pos": Vector2(5 * 32 + 16, 0 * 32 - 4)},
		{"tex": TEX_TREE, "pos": Vector2(15 * 32 + 16, 0 * 32 - 8)},
		{"tex": TEX_TREE, "pos": Vector2(18 * 32 + 16, 0 * 32 - 4)},

		# Bushes scattered on grass areas
		{"tex": TEX_BUSH, "pos": Vector2(1 * 32 + 16, 2 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(2 * 32 + 16, 3 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(3 * 32 + 16, 1 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(1 * 32 + 16, 7 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(3 * 32 + 16, 10 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(15 * 32 + 16, 9 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(17 * 32 + 16, 10 * 32 + 16)},
		{"tex": TEX_BUSH, "pos": Vector2(12 * 32 + 16, 9 * 32 + 16)},

		# Mossy rocks near the void edge and within ruins
		{"tex": TEX_ROCK, "pos": Vector2(4 * 32 + 16, 6 * 32 + 16)},
		{"tex": TEX_ROCK, "pos": Vector2(14 * 32 + 16, 7 * 32 + 16)},
		{"tex": TEX_ROCK, "pos": Vector2(8 * 32 + 16, 10 * 32 + 16)},
		{"tex": TEX_ROCK, "pos": Vector2(16 * 32 + 16, 2 * 32 + 16)},

		# Trees along bottom wall
		{"tex": TEX_TREE, "pos": Vector2(7 * 32 + 16, 11 * 32 + 24)},
		{"tex": TEX_TREE, "pos": Vector2(12 * 32 + 16, 11 * 32 + 28)},
		{"tex": TEX_TREE, "pos": Vector2(17 * 32 + 16, 11 * 32 + 24)},
	]

	for deco in decorations:
		var s = Sprite2D.new()
		s.texture = deco.tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = deco.pos
		s.z_index = 1  # Above ground tiles, below characters
		add_child(s)

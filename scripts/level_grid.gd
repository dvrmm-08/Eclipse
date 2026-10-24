extends Node2D

# Preloaded genuine pixel-art environment textures
const TEX_GRASS_1 = preload("res://assets/environment/grass/grass_1.png")
const TEX_GRASS_2 = preload("res://assets/environment/grass/grass_2.png")
const TEX_GRASS_3 = preload("res://assets/environment/grass/grass_3.png")
const TEX_GRASS_DARK = preload("res://assets/environment/grass/grass_dark.png")

const TEX_DIRT_1 = preload("res://assets/environment/dirt/dirt_1.png")
const TEX_DIRT_2 = preload("res://assets/environment/dirt/dirt_2.png")
const TEX_DIRT_3 = preload("res://assets/environment/dirt/dirt_3.png")
const TEX_DIRT_DARK = preload("res://assets/environment/dirt/dirt_dark.png")

const TEX_STONE_FLOOR = preload("res://assets/environment/stone/stone_floor_1.png")
const TEX_STONE_FLOOR_DARK = preload("res://assets/environment/stone/stone_floor_dark.png")
const TEX_STONE_WALL = preload("res://assets/environment/stone/stone_wall.png")
const TEX_STONE_PILLAR = preload("res://assets/environment/stone/stone_pillar.png")

const TEX_VOID_NORMAL = preload("res://assets/environment/void/void_normal.png")
const TEX_VOID_ECLIPSE = preload("res://assets/environment/eclipse/void_eclipse.png")
const TEX_CYAN_PATH = preload("res://assets/environment/eclipse/cyan_path.png")

var void_sprites: Array[Sprite2D] = []
var bridge_sprites: Array[Sprite2D] = []
var terrain_records: Array[Dictionary] = []

func build_map(layout: Array[String]) -> void:
	for child in get_children():
		child.queue_free()
		
	void_sprites.clear()
	bridge_sprites.clear()
	terrain_records.clear()
	
	for y in range(layout.size()):
		var row = layout[y]
		for x in range(row.length()):
			var char_tile = row[x]
			var pos = Vector2(x * 32 + 16, y * 32 + 16)
			_spawn_tile(char_tile, pos, x, y)

func _spawn_tile(ch: String, pos: Vector2, gx: int, gy: int) -> void:
	var sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	
	var col_layer: int = 0
	
	match ch:
		'#': # Mossy Stone Wall
			sprite.texture = TEX_STONE_WALL
			col_layer = 1 # Solid_Walls
		'P': # Ancient Pillar
			sprite.texture = TEX_STONE_PILLAR
			col_layer = 1 # Solid_Walls
		'~': # Deep Void Chasm
			sprite.texture = TEX_VOID_NORMAL
			col_layer = 18 # Layer 2 (Void_Chasm) + Layer 5 (Void_Shadow_Barrier)
			void_sprites.append(sprite)
		'=': # Hidden Cyan Bridge
			# In normal world, hidden path appears identical to void
			sprite.texture = TEX_VOID_NORMAL
			col_layer = 2 # Layer 2 ONLY (Void_Chasm) - Wanderer blocked, Shadow walks!
			bridge_sprites.append(sprite)
		',': # Grass (3 natural variants)
			var variant = (gx * 3 + gy * 7) % 3
			var norm_tex = TEX_GRASS_1
			if variant == 1: norm_tex = TEX_GRASS_2
			elif variant == 2: norm_tex = TEX_GRASS_3
			sprite.texture = norm_tex
			terrain_records.append({"sprite": sprite, "normal": norm_tex, "dark": TEX_GRASS_DARK})
		':': # Dirt Path (3 natural variants)
			var d_var = (gx * 5 + gy * 11) % 3
			var d_tex = TEX_DIRT_1
			if d_var == 1: d_tex = TEX_DIRT_2
			elif d_var == 2: d_tex = TEX_DIRT_3
			sprite.texture = d_tex
			terrain_records.append({"sprite": sprite, "normal": d_tex, "dark": TEX_DIRT_DARK})
		'.': # Stone Floor
			sprite.texture = TEX_STONE_FLOOR
			terrain_records.append({"sprite": sprite, "normal": TEX_STONE_FLOOR, "dark": TEX_STONE_FLOOR_DARK})
		' ': # Open void
			sprite.texture = TEX_VOID_NORMAL
			col_layer = 18
			void_sprites.append(sprite)
			
	add_child(sprite)
	
	if col_layer > 0:
		var body = StaticBody2D.new()
		body.position = pos
		body.collision_layer = col_layer
		body.collision_mask = 0
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(32, 32)
		shape.shape = rect
		body.add_child(shape)
		add_child(body)

func set_eclipse_mode(active: bool) -> void:
	# 1. Void tiles shift between near-black and deep crimson red
	for s in void_sprites:
		s.texture = TEX_VOID_ECLIPSE if active else TEX_VOID_NORMAL
		
	# 2. Cyan bridges ignite with luminous bright cyan or disappear into void
	for s in bridge_sprites:
		s.texture = TEX_CYAN_PATH if active else TEX_VOID_NORMAL
		
	# 3. Ground terrain becomes darkened/subdued in Eclipse
	for rec in terrain_records:
		rec.sprite.texture = rec.dark if active else rec.normal

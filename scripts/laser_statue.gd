extends StaticBody2D

@export var cast_direction: Vector2 = Vector2.DOWN
@export var max_distance: float = 600.0
@export var is_active: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var raycast: RayCast2D = $RayCast2D
@onready var laser_line: Line2D = $LaserLine
@onready var emitter_point: Marker2D = $EmitterPoint

var shadow_ref: CharacterBody2D = null
var wanderer_ref: CharacterBody2D = null

func _init_nodes() -> void:
	if not raycast and has_node("RayCast2D"):
		raycast = $RayCast2D
	if not laser_line and has_node("LaserLine"):
		laser_line = $LaserLine
	if not emitter_point and has_node("EmitterPoint"):
		emitter_point = $EmitterPoint
	if not sprite and has_node("Sprite2D"):
		sprite = $Sprite2D

func _ready() -> void:
	_init_nodes()
	collision_layer = 1
	collision_mask = 0
	
	if raycast:
		raycast.collision_mask = 5
		raycast.collide_with_bodies = true
		raycast.collide_with_areas = false
		raycast.target_position = cast_direction.normalized() * max_distance
	
	if laser_line:
		laser_line.width = 4.0
		laser_line.default_color = Color(1.0, 0.15, 0.2, 0.95)
	
	_find_characters()

func _find_characters() -> void:
	if is_inside_tree() and get_tree():
		var shadows = get_tree().get_nodes_in_group("shadow")
		if shadows.size() > 0:
			shadow_ref = shadows[0]
		var wanderers = get_tree().get_nodes_in_group("wanderer")
		if wanderers.size() > 0:
			wanderer_ref = wanderers[0]
	else:
		var p = get_parent()
		while p:
			var w = p.get_node_or_null("Wanderer")
			if w: wanderer_ref = w
			var s = p.get_node_or_null("Shadow")
			if s: shadow_ref = s
			p = p.get_parent()

func _physics_process(_delta: float) -> void:
	_init_nodes()
	if not is_active:
		if laser_line:
			laser_line.visible = false
		return
		
	if not raycast or not laser_line or not emitter_point:
		return
		
	laser_line.visible = true
	raycast.force_raycast_update()
	
	var start_pos = emitter_point.global_position
	var end_pos: Vector2
	
	if raycast.is_colliding():
		end_pos = raycast.get_collision_point()
	else:
		end_pos = start_pos + raycast.target_position
		
	laser_line.global_position = Vector2.ZERO
	laser_line.points = PackedVector2Array([start_pos, end_pos])
	
	_check_shadow_hit(start_pos, end_pos)

func _check_shadow_hit(a: Vector2, b: Vector2) -> void:
	if not shadow_ref or not shadow_ref.visible:
		_find_characters()
		if not shadow_ref or not shadow_ref.visible:
			return

	if not shadow_ref.get("is_controlled"):
		return
		
	var p = shadow_ref.global_position + Vector2(0, -10)
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq < 0.001:
		return
		
	var t = clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var proj = a + t * ab
	var dist = p.distance_to(proj)
	
	if dist < 12.0:
		_repel_shadow()

func _repel_shadow() -> void:
	if not shadow_ref or not wanderer_ref:
		return
	print("LASER HIT: Shadow repelled by laser beam!")
	shadow_ref.global_position = wanderer_ref.global_position
	
	if is_inside_tree() and get_tree():
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_method("show_message"):
			ui.show_message("The searing red gaze burns your shadow, repelling it back to your physical body!")

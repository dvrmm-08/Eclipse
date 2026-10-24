extends StaticBody2D

@export var cast_direction: Vector2 = Vector2.DOWN
@export var max_distance: float = 500.0
@export var is_active: bool = true
@export var gaze_color: Color = Color(1.0, 0.5, 0.2, 0.45)

@onready var sprite: Sprite2D = $Sprite2D
@onready var raycast: RayCast2D = $RayCast2D
@onready var gaze_line: Line2D = $GazeLine
@onready var eye_point: Marker2D = $EyePoint

var shadow_ref: CharacterBody2D = null
var wanderer_ref: CharacterBody2D = null
var _repel_cooldown: float = 0.0

func _init_nodes() -> void:
	if not raycast and has_node("RayCast2D"):
		raycast = $RayCast2D
	if not gaze_line and has_node("GazeLine"):
		gaze_line = $GazeLine
	if not eye_point and has_node("EyePoint"):
		eye_point = $EyePoint
	if not sprite and has_node("Sprite2D"):
		sprite = $Sprite2D

func _ready() -> void:
	_init_nodes()
	collision_layer = 1
	collision_mask = 0
	
	if raycast:
		raycast.collision_mask = 5 # Layer 1 (Walls) + Layer 3 (Wanderer)
		raycast.collide_with_bodies = true
		raycast.collide_with_areas = false
		raycast.target_position = cast_direction.normalized() * max_distance
	
	if gaze_line:
		gaze_line.width = 6.0
		gaze_line.default_color = gaze_color
		
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

func _physics_process(delta: float) -> void:
	_init_nodes()
	if _repel_cooldown > 0.0:
		_repel_cooldown -= delta

	if not is_active:
		if gaze_line:
			gaze_line.visible = false
		return
		
	if not raycast or not gaze_line or not eye_point:
		return
		
	gaze_line.visible = true
	raycast.target_position = cast_direction.normalized() * max_distance
	raycast.force_raycast_update()
	
	var start_pos = eye_point.global_position
	var end_pos: Vector2
	
	if raycast.is_colliding():
		end_pos = raycast.get_collision_point()
	else:
		end_pos = start_pos + raycast.target_position
		
	gaze_line.global_position = Vector2.ZERO
	gaze_line.points = PackedVector2Array([start_pos, end_pos])
	
	_check_detection(start_pos, end_pos)

func _check_detection(a: Vector2, b: Vector2) -> void:
	if _repel_cooldown > 0.0:
		return
		
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
	
	# If shadow crosses unobstructed line of sight
	if dist < 14.0:
		_on_spotted()

func _on_spotted() -> void:
	if not shadow_ref or not wanderer_ref:
		return
	_repel_cooldown = 1.0
	print("WATCHER SPOTTED: Shadow entered watcher statue's line-of-sight!")
	shadow_ref.global_position = wanderer_ref.global_position
	
	if is_inside_tree() and get_tree():
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_method("show_message"):
			ui.show_message("The Watcher's gaze seared your shadow! Seek the blind spot.")

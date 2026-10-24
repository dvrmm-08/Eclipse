extends StaticBody2D

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Watcher Statue
#
# Fully customizable in Godot's 2D Editor:
#   - Moving this node sets the watcher position.
#   - Rotating this node in the 2D editor rotates its detection direction automatically.
#   - vision_range and fov_angle are directly editable in the Inspector.
#   - Solid masonry walls block its line of sight.
#   - No permanently visible red vision shapes during normal gameplay.
#     (debug_visualization is false by default).
# ═════════════════════════════════════════════════════════════════════════════

@export var vision_range: float = 230.0 # ~7 tiles
@export var fov_angle: float = 90.0 # FOV cone in degrees
@export var facing_direction: Vector2 = Vector2.DOWN # Base local direction
@export var is_active: bool = true
@export var debug_visualization: bool = false # Disabled by default for clean gameplay

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var eye_point: Marker2D = get_node_or_null("EyePoint")

var wanderer_ref: CharacterBody2D = null
var _cone_points: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	add_to_group("watcher")
	collision_layer = 1 # Solid_Walls
	collision_mask = 0
	_find_wanderer()
	if debug_visualization:
		_update_cone_points()

func _find_wanderer() -> void:
	if is_inside_tree() and get_tree():
		var wanderers = get_tree().get_nodes_in_group("wanderer")
		if wanderers.size() > 0:
			wanderer_ref = wanderers[0]
	if not wanderer_ref:
		var p = get_parent()
		while p:
			var w = p.get_node_or_null("Wanderer")
			if w:
				wanderer_ref = w
				break
			p = p.get_parent()

func get_eye_global_position() -> Vector2:
	if eye_point:
		return eye_point.global_position
	return global_position + Vector2(0, -36).rotated(global_rotation)

func get_current_facing_direction() -> Vector2:
	# Rotates facing direction by the node's global rotation in the editor
	return facing_direction.rotated(global_rotation).normalized()

func can_see_wanderer() -> bool:
	if not is_active:
		return false
	if not wanderer_ref or not wanderer_ref.is_inside_tree():
		_find_wanderer()
		if not wanderer_ref:
			return false

	var eye_pos = get_eye_global_position()
	var target_pos = wanderer_ref.global_position + Vector2(0, -14)

	# 1. Range check
	var dist = eye_pos.distance_to(target_pos)
	if dist > vision_range or dist < 2.0:
		return false

	# 2. Angle check (effective direction follows node rotation)
	var effective_facing = get_current_facing_direction()
	var dir_to_target = (target_pos - eye_pos).normalized()
	var angle_diff = absf(effective_facing.angle_to(dir_to_target))
	var half_fov = deg_to_rad(fov_angle * 0.5)
	if angle_diff > half_fov:
		return false

	# 3. Line of sight physics raycast (occluded by Solid_Walls, layer 1)
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return false

	var query = PhysicsRayQueryParameters2D.create(eye_pos, target_pos, 1) # Layer 1: Solid_Walls
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)

	# If no wall was hit before reaching target, target is seen!
	if result.is_empty():
		return true

	# If something was hit, verify distance relative to target
	var hit_dist = eye_pos.distance_to(result.position)
	return hit_dist >= dist - 4.0

func _physics_process(_delta: float) -> void:
	if debug_visualization and is_active:
		_update_cone_points()
		queue_redraw()

func _update_cone_points() -> void:
	if not is_inside_tree():
		return
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return

	var eye_pos = get_eye_global_position()
	var local_eye = to_local(eye_pos)
	var center_angle = get_current_facing_direction().angle()
	var half_fov = deg_to_rad(fov_angle * 0.5)
	var num_rays = 17

	var pts: Array[Vector2] = [local_eye]
	for i in range(num_rays):
		var t = float(i) / float(num_rays - 1)
		var angle = center_angle - half_fov + t * (half_fov * 2.0)
		var dir = Vector2(cos(angle), sin(angle))
		var ray_end = eye_pos + dir * vision_range

		var query = PhysicsRayQueryParameters2D.create(eye_pos, ray_end, 1) # Layer 1 (Walls)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.exclude = [get_rid()]
		var res = space_state.intersect_ray(query)

		var hit_point = res.position if not res.is_empty() else ray_end
		pts.append(to_local(hit_point))

	_cone_points = PackedVector2Array(pts)

func _draw() -> void:
	if not debug_visualization or not is_active or _cone_points.size() < 3:
		return

	# Only drawn when explicitly enabled for debugging in Inspector
	draw_colored_polygon(_cone_points, Color(1.0, 0.2, 0.2, 0.1))
	for i in range(1, _cone_points.size() - 1):
		draw_line(_cone_points[i], _cone_points[i + 1], Color(1.0, 0.3, 0.3, 0.3), 1.0)

extends "res://scripts/level_base.gd"

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2 — BLIND SPOT
#
# Mechanics:
#   - Two Watcher Statues at (2, 2) and (5, 2) watching the platform
#   - Physics-based line of sight blocked by L-shaped stone masonry wall
#   - Discoverable blind spot at tile (4, 8)
#   - P-switch blocked if either watcher can see the white Wanderer
#   - One physical timed red laser crossing Row 4
#   - Editable cyan bridge leading from (5, 8) to far platform (15, 6)
#   - Ancient Mechanism (Lever) at (17, 3) unlocking the Gate at (2, 9)
#   - Cinematic Ending Sequence with Wanderer and Shadow confrontation
# ═════════════════════════════════════════════════════════════════════════════

@onready var watcher_a: StaticBody2D = get_node_or_null("Objects/WatcherStatueA")
@onready var watcher_b: StaticBody2D = get_node_or_null("Objects/WatcherStatueB")
@onready var timed_laser: Node2D = get_node_or_null("Objects/TimedLaser")
@onready var tablet: Area2D = get_node_or_null("Objects/Tablet")
@onready var mechanism: Area2D = get_node_or_null("Objects/Mechanism")
@onready var gate: Area2D = get_node_or_null("Objects/Gate")

var ending_scare_triggered: bool = false

func _ready() -> void:
	level_title = "LEVEL 2"
	level_subtitle = "BLIND SPOT"
	next_level_path = "" # Handled by custom cinematic ending

	super._ready()

	# Connect mechanism (lever) to gate
	if mechanism and gate:
		mechanism.target_gate = gate
		if not mechanism.state_changed.is_connected(_on_mechanism_activated):
			mechanism.state_changed.connect(_on_mechanism_activated)

	# Set up tablet clue
	if tablet:
		tablet.message = "Two eyes seek the flesh that stays.\nA red thread divides the way.\nWhere their sightlines fail,\nthe other may pass."

	# Fixed camera centers on 640x384 room
	if camera:
		camera.global_position = Vector2(320, 192)

func _on_mechanism_activated(active: bool) -> void:
	if active and ui and ui.has_method("show_message"):
		ui.show_message("The distant iron gate unlatched with a heavy mechanical groan.", 3.0)

func toggle_dimension() -> void:
	# If ending cinematic is active, switching is strictly blocked
	if ending_scare_triggered or is_completing:
		return

	# If in normal mode, check if watchers have line of sight to Wanderer
	if not eclipse_active:
		if _are_watchers_alerted():
			if ui and ui.has_method("show_message"):
				ui.show_message("THE WATCHERS CAN SEE YOU", 2.0)
			return

	super.toggle_dimension()

func _are_watchers_alerted() -> bool:
	var watchers = get_tree().get_nodes_in_group("watcher") if (is_inside_tree() and get_tree()) else []
	for w in watchers:
		if w is CanvasItem and not w.is_visible_in_tree():
			continue
		if w.has_method("can_see_wanderer") and w.can_see_wanderer():
			return true

	# Fallback check direct references if group is empty
	if watchers.is_empty():
		if watcher_a and watcher_a.has_method("can_see_wanderer") and watcher_a.can_see_wanderer():
			return true
		if watcher_b and watcher_b.has_method("can_see_wanderer") and watcher_b.can_see_wanderer():
			return true

	return false

func _unhandled_input(event: InputEvent) -> void:
	if ending_scare_triggered:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				if ui and ui.has_node("EndingCard"):
					get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
					return
		return # Block normal inputs (P, R, etc.) during cinematic

	super._unhandled_input(event)

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2 ENDING CINEMATIC
# ═════════════════════════════════════════════════════════════════════════════

func complete_level() -> void:
	if ending_scare_triggered:
		return
	ending_scare_triggered = true
	is_completing = true
	can_switch = false

	_run_ending_cinematic()

func _run_ending_cinematic() -> void:
	print("LEVEL 2 ENDING: Beginning atmospheric ending cinematic...")

	# 1. Lock player input and disable active control
	if wanderer:
		wanderer.input_disabled = true
		wanderer.is_controlled = false
		wanderer.velocity = Vector2.ZERO
	if shadow:
		shadow.input_disabled = true
		shadow.is_controlled = false
		shadow.velocity = Vector2.ZERO

	# Hide gameplay HUD elements (controls, dimension indicator)
	if ui and ui.has_method("hide_hud"):
		ui.hide_hud()

	var audio_mgr = get_node_or_null("/root/AudioManager")

	# Settle time in front of exit
	await get_tree().create_timer(0.8).timeout

	# ── SCENE A: False victory ──
	print("CINEMATIC: Scene A (False victory) starting...")
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue("Wanderer", "Finally...", 2.4)
	elif ui and ui.has_method("show_message"):
		ui.show_message("Wanderer: \"Finally...\"", 2.4)

	await get_tree().create_timer(2.6).timeout

	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue(0.3)
	await get_tree().create_timer(0.4).timeout

	# ── SCENE B: The Shadow appears directly behind Wanderer ──
	print("CINEMATIC: Scene B (Shadow appears behind Wanderer) starting...")
	# CRITICAL REQUIREMENT: Position Shadow directly behind Wanderer silently while hidden
	var shadow_spawn_pos = _calculate_behind_position(wanderer)

	if shadow:
		shadow.visible = false
		shadow.global_position = shadow_spawn_pos
		shadow.velocity = Vector2.ZERO
		if shadow.get_node_or_null("CollisionShape2D"):
			shadow.get_node("CollisionShape2D").disabled = true

		# Orient Shadow facing Wanderer
		var to_wanderer = (wanderer.global_position - shadow.global_position).normalized()
		var s_sprite = shadow.get_node_or_null("Sprite2D")
		if s_sprite:
			s_sprite.flip_h = (to_wanderer.x < 0)
			s_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Reveal Shadow silently standing behind
		shadow.visible = true

	# Subtle presence sound effect
	if audio_mgr and audio_mgr.has_method("play_message_sfx"):
		audio_mgr.play_message_sfx()

	# Fade in ending conversation music as Shadow is revealed
	if audio_mgr and audio_mgr.has_method("play_ending_music"):
		audio_mgr.play_ending_music(1.5, -12.0)

	# 1.5s tense silence — player notices the Shadow
	await get_tree().create_timer(1.5).timeout

	# Shadow slowly takes a step closer
	if shadow and wanderer:
		var step_dir = (wanderer.global_position - shadow.global_position).normalized()
		var step_dist = clampf(shadow.global_position.distance_to(wanderer.global_position) - 18.0, 4.0, 10.0)
		var s_step = create_tween()
		s_step.tween_property(shadow, "global_position", shadow.global_position + step_dir * step_dist, 0.8).set_trans(Tween.TRANS_SINE)
		await s_step.finished

	# Red chest gem begins to flicker subtly
	var shadow_sprite = shadow.get_node_or_null("Sprite2D") if shadow else null
	if shadow_sprite:
		if audio_mgr and audio_mgr.has_method("play_ui_hover"):
			audio_mgr.play_ui_hover()
		var flk = create_tween()
		flk.tween_property(shadow_sprite, "modulate", Color(1.8, 0.45, 0.45, 1.0), 0.12)
		flk.tween_property(shadow_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		flk.tween_property(shadow_sprite, "modulate", Color(1.9, 0.4, 0.4, 1.0), 0.15)
		flk.tween_property(shadow_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		await flk.finished

	# Wanderer senses something is wrong and turns slightly / hesitates
	var wanderer_sprite = wanderer.get_node_or_null("Sprite2D") if wanderer else null
	if wanderer and shadow and wanderer_sprite:
		var to_s = (shadow.global_position - wanderer.global_position).normalized()
		wanderer_sprite.flip_h = (to_s.x < 0)
		var turn_tw = create_tween()
		turn_tw.tween_property(wanderer_sprite, "position:y", -25.0, 0.15)
		turn_tw.tween_property(wanderer_sprite, "position:y", -23.0, 0.15)
		await turn_tw.finished

	await get_tree().create_timer(0.4).timeout

	# Dialogue 2: Wanderer
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue("Wanderer", "Wait... I thought you were just my reflection.", 2.8)
	elif ui and ui.has_method("show_message"):
		ui.show_message("Wanderer: \"Wait... I thought you were just my reflection.\"", 2.8)

	await get_tree().create_timer(3.0).timeout

	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue(0.3)
	await get_tree().create_timer(0.4).timeout

	# Dialogue 3: Shadow
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue("Shadow", "Then why did you leave me behind?", 3.0)
	elif ui and ui.has_method("show_message"):
		ui.show_message("Shadow: \"Then why did you leave me behind?\"", 3.0)

	await get_tree().create_timer(3.2).timeout

	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue(0.3)
	await get_tree().create_timer(0.4).timeout

	# ── SCENE C: The reveal ──
	print("CINEMATIC: Scene C (The reveal) starting...")
	# Wanderer hesitates and takes a small step backwards
	if wanderer and shadow:
		var retreat_dir = (wanderer.global_position - shadow.global_position).normalized()
		var w_step = create_tween()
		w_step.tween_property(wanderer, "global_position", wanderer.global_position + retreat_dir * 10.0, 0.6).set_trans(Tween.TRANS_SINE)
		await w_step.finished

		# Shadow advances one measured step
		var s_advance = create_tween()
		s_advance.tween_property(shadow, "global_position", shadow.global_position + retreat_dir * 8.0, 0.7).set_trans(Tween.TRANS_SINE)
		await s_advance.finished

	await get_tree().create_timer(0.5).timeout

	# Dialogue 4: Wanderer
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue("Wanderer", "What are you?", 1.8)
	elif ui and ui.has_method("show_message"):
		ui.show_message("Wanderer: \"What are you?\"", 1.8)

	await get_tree().create_timer(1.8).timeout

	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue(0.3)
	await get_tree().create_timer(0.4).timeout

	# Dialogue 5: Shadow
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue("Shadow", "You remember.", 2.5)
	elif ui and ui.has_method("show_message"):
		ui.show_message("Shadow: \"You remember.\"", 2.5)

	await get_tree().create_timer(2.0).timeout

	# Short pause
	await get_tree().create_timer(0.6).timeout

	# Red gem flashes once
	if shadow_sprite:
		shadow_sprite.modulate = Color(3.5, 0.35, 0.35, 1.0)
	if audio_mgr:
		if audio_mgr.has_method("play_reveal_sfx"):
			audio_mgr.play_reveal_sfx()
		audio_mgr.fade_out_music(2.0)

	await get_tree().create_timer(0.6).timeout

	# Fade screen smoothly to black
	print("CINEMATIC: Fading to black...")
	var fade_rect = ColorRect.new()
	fade_rect.name = "CinematicFadeOverlay"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ui:
		ui.add_child(fade_rect)
	else:
		add_child(fade_rect)

	var fade_tw = create_tween()
	fade_tw.tween_property(fade_rect, "color", Color(0, 0, 0, 1.0), 1.8)
	await fade_tw.finished

	# ── SCENE D: Final screen (Minimalist ending card) ──
	print("CINEMATIC: Scene D (Ending Card) presenting...")
	await get_tree().create_timer(0.8).timeout

	if ui and ui.has_method("show_ending_card"):
		ui.show_ending_card()
	elif ui and ui.has_method("show_banner"):
		ui.show_banner("ECLIPSE", "Some shadows remember.\n\nThe End... for now.")
	print("CINEMATIC: Completed successfully!")

# ═════════════════════════════════════════════════════════════════════════════
# SHADOW BEHIND WANDERER CALCULATION
# ═════════════════════════════════════════════════════════════════════════════

func _calculate_behind_position(wanderer_node: CharacterBody2D) -> Vector2:
	if not wanderer_node:
		return Vector2(102, 280) # Safe default on Level 2 gate platform

	var w_pos = wanderer_node.global_position
	var facing = wanderer_node.get("facing_direction")
	if facing == null or facing.length_squared() < 0.01:
		facing = Vector2.DOWN
	facing = facing.normalized()

	var base_behind = -facing
	var candidate_distances = [28.0, 24.0, 32.0, 20.0]
	var angle_offsets = [0.0, 15.0, -15.0, 30.0, -30.0, 45.0, -45.0]

	var space_state = get_world_2d().direct_space_state
	var default_pos = w_pos + base_behind * 28.0

	if not space_state:
		return default_pos

	for dist in candidate_distances:
		for angle_deg in angle_offsets:
			var dir = base_behind.rotated(deg_to_rad(angle_deg))
			var candidate = w_pos + dir * dist

			# Boundary check inside the 640x384 room
			if candidate.x < 36.0 or candidate.x > 604.0 or candidate.y < 36.0 or candidate.y > 348.0:
				continue

			# Point check against Solid_Walls (Layer 1)
			var query = PhysicsPointQueryParameters2D.new()
			query.position = candidate + Vector2(0, -5) # Shadow body center
			query.collision_mask = 1 # Solid_Walls
			query.collide_with_bodies = true
			query.collide_with_areas = false
			var hits = space_state.intersect_point(query, 1)

			if hits.is_empty():
				# Check raycast between Wanderer and candidate to ensure clear space
				var ray = PhysicsRayQueryParameters2D.create(w_pos + Vector2(0, -5), candidate + Vector2(0, -5), 1)
				var ray_hit = space_state.intersect_ray(ray)
				if ray_hit.is_empty():
					return candidate

	# If rear cone was obstructed, check lateral angles
	for angle_deg in [60.0, -60.0, 75.0, -75.0, 90.0, -90.0]:
		var dir = base_behind.rotated(deg_to_rad(angle_deg))
		var candidate = w_pos + dir * 24.0
		if candidate.x > 36.0 and candidate.x < 604.0 and candidate.y > 36.0 and candidate.y < 348.0:
			var query = PhysicsPointQueryParameters2D.new()
			query.position = candidate + Vector2(0, -5)
			query.collision_mask = 1
			query.collide_with_bodies = true
			if space_state.intersect_point(query, 1).is_empty():
				return candidate

	return default_pos

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
#   - Scripted Ending Scare sequence upon completing the level
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
	next_level_path = "" # Handled by custom ending scare

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

# Overriding level completion for the scripted ending scare
func complete_level() -> void:
	if ending_scare_triggered:
		return
	ending_scare_triggered = true
	is_completing = true

	_run_ending_scare()

func _run_ending_scare() -> void:
	print("LEVEL 2 ENDING: Triggering scripted ending scare...")

	# 1. Lock player input
	if wanderer:
		wanderer.input_disabled = true
		wanderer.is_controlled = false
		wanderer.velocity = Vector2.ZERO
	if shadow:
		shadow.is_controlled = false
		shadow.velocity = Vector2.ZERO

	# 2. Manifest the Shadow in the doorway of the gate
	if shadow and gate:
		shadow.global_position = gate.global_position + Vector2(0, -8)
		shadow.visible = true
		if shadow.get_node_or_null("CollisionShape2D"):
			shadow.get_node("CollisionShape2D").disabled = true

	# 3. Shadow turns toward Wanderer
	var dir_to_wanderer = Vector2.DOWN
	if wanderer and shadow:
		dir_to_wanderer = (wanderer.global_position - shadow.global_position).normalized()
		var shadow_sprite = shadow.get_node_or_null("Sprite2D")
		if shadow_sprite:
			shadow_sprite.flip_h = (dir_to_wanderer.x < 0)
			# Red eerie glow on shadow's symbol
			shadow_sprite.modulate = Color(2.0, 0.4, 0.4, 1.0)

	# 4. Cinematic pause then autonomous step forward
	await get_tree().create_timer(0.6).timeout

	if shadow and wanderer:
		var scare_tween = create_tween()
		scare_tween.set_parallel(true)
		# Shadow takes deliberate autonomous steps toward Wanderer
		scare_tween.tween_property(shadow, "global_position", shadow.global_position + dir_to_wanderer * 28.0, 0.9).set_trans(Tween.TRANS_SINE)
		# Wanderer is forced back
		scare_tween.tween_property(wanderer, "global_position", wanderer.global_position + Vector2(0, 24.0), 0.9).set_trans(Tween.TRANS_SINE)

	if ui and ui.has_method("show_message"):
		ui.show_message("...The shadow stepped forward. It refuses to return.", 3.5)

	await get_tree().create_timer(1.2).timeout

	# 5. Visual flicker and fade to black
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1.0), 1.5)
	await fade_tween.finished

	# 6. Intentional ending card
	if ui and ui.has_method("show_banner"):
		ui.show_banner("LEVEL 2 COMPLETE", "TO BE CONTINUED IN LEVEL 3 — THE VESSEL")

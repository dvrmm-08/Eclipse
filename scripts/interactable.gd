extends Area2D

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Reusable Interactable Object
# Handles:
#   - TABLET: Shows ancient riddle / mechanic hint
#   - NOTE: Shows optional lore
#   - LEVER: Mechanically unlocks the exit gate (ONLY operable by Shadow form)
#   - GATE: Exit portal (physically blocked by GateBarrier until lever is pulled)
# ═════════════════════════════════════════════════════════════════════════════

enum Type {
	TABLET,
	NOTE,
	LEVER,
	GATE
}

const TEX_TABLET = preload("res://assets/environment/props/tablet.png")
const TEX_NOTE = preload("res://assets/environment/props/note.png")
const TEX_LEVER_OFF = preload("res://assets/environment/props/lever_off.png")
const TEX_LEVER_ON = preload("res://assets/environment/props/lever_on.png")
const TEX_GATE_CLOSED = preload("res://assets/environment/props/gate_closed.png")
const TEX_GATE_OPEN = preload("res://assets/environment/props/gate_open.png")

@export var type: Type = Type.TABLET:
	set(val):
		type = val
		_setup_gate_barrier()
		_update_visuals()

@export_multiline var message: String = ""
@export var is_active: bool = false:
	set(val):
		is_active = val
		_setup_gate_barrier()
		_update_visuals()

@export var target_gate: Area2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
var barrier_body: StaticBody2D = null

var player_in_range: bool = false
var current_interactor: Node2D = null

signal interacted(interactor: Node2D)
signal state_changed(active: bool)

func _ready() -> void:
	collision_layer = 32 # Layer 6: Interactables
	collision_mask = 12  # Layer 3 (Wanderer) + Layer 4 (Shadow)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if not prompt_label:
		prompt_label = Label.new()
		prompt_label.name = "PromptLabel"
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.position = Vector2(-50, -44)
		prompt_label.size = Vector2(100, 20)
		prompt_label.add_theme_font_size_override("font_size", 10)
		add_child(prompt_label)

	prompt_label.visible = false
	_setup_gate_barrier()
	_update_visuals()

func _setup_gate_barrier() -> void:
	if not barrier_body and has_node("GateBarrier"):
		barrier_body = $GateBarrier

	if type == Type.GATE:
		if not barrier_body:
			barrier_body = StaticBody2D.new()
			barrier_body.name = "GateBarrier"
			barrier_body.collision_layer = 1 # Solid_Walls (Layer 1)
			barrier_body.collision_mask = 0

			var col = CollisionShape2D.new()
			var rect = RectangleShape2D.new()
			rect.size = Vector2(32, 28)
			col.shape = rect
			col.position = Vector2(0, 4)
			barrier_body.add_child(col)
			add_child(barrier_body)

		if barrier_body:
			barrier_body.set_collision_layer_value(1, not is_active)
	else:
		if barrier_body:
			barrier_body.set_collision_layer_value(1, false)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if current_interactor and current_interactor.get("is_controlled") == true:
			interact(current_interactor)

func _get_ui() -> Node:
	if is_inside_tree() and get_tree():
		var ui_node = get_tree().get_first_node_in_group("ui")
		if ui_node:
			return ui_node
	var p = get_parent()
	while p:
		var u = p.get_node_or_null("UIOverlay")
		if u:
			return u
		p = p.get_parent()
	return null

func _get_level() -> Node:
	if is_inside_tree() and get_tree():
		var lvl = get_tree().get_first_node_in_group("level")
		if lvl:
			return lvl
	var p = get_parent()
	while p:
		if p.has_method("complete_level"):
			return p
		p = p.get_parent()
	return null

func interact(interactor: Node2D) -> void:
	var ui = _get_ui()
	var level = _get_level()

	if type == Type.LEVER:
		# Mandatory requirement: Lever can ONLY be operated by the Shadow form in Eclipse mode
		if interactor.name != "Shadow":
			if ui and ui.has_method("show_message"):
				ui.show_message("The mechanism resists mortal hands. Only a shadow can move it.")
			return

		if not is_active:
			is_active = true
			if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
				var audio_mgr = get_tree().root.get_node("AudioManager")
				audio_mgr.play_mechanism_sfx()
			emit_signal("state_changed", true)
			if target_gate and target_gate.has_method("open_gate"):
				target_gate.open_gate()
			if ui and ui.has_method("show_message"):
				ui.show_message("A heavy stone mechanism echoes in the distance. The exit gate has unlocked!")
		else:
			if ui and ui.has_method("show_message"):
				ui.show_message("The mechanism is already unlocked. The exit path lies open.")

	elif type == Type.TABLET:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			var audio_mgr = get_tree().root.get_node("AudioManager")
			audio_mgr.play_tablet_sfx()
		if ui and ui.has_method("show_message"):
			ui.show_message(message)

	elif type == Type.NOTE:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			var audio_mgr = get_tree().root.get_node("AudioManager")
			audio_mgr.play_message_sfx()
		if ui and ui.has_method("show_message"):
			ui.show_message(message)

	elif type == Type.GATE:
		if is_active:
			if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
				var audio_mgr = get_tree().root.get_node("AudioManager")
				audio_mgr.play_gate_sfx()
			if level and level.has_method("complete_level"):
				level.complete_level()
		else:
			if ui and ui.has_method("show_message"):
				ui.show_message("The gate is sealed shut by a heavy iron lock.")

	emit_signal("interacted", interactor)

func open_gate() -> void:
	if not is_active:
		is_active = true
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			var audio_mgr = get_tree().root.get_node("AudioManager")
			audio_mgr.play_gate_sfx()
		emit_signal("state_changed", true)

func _update_visuals() -> void:
	if not sprite and has_node("Sprite2D"):
		sprite = $Sprite2D
	if not prompt_label and has_node("PromptLabel"):
		prompt_label = $PromptLabel

	if not sprite:
		return

	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 1
	sprite.vframes = 1

	match type:
		Type.LEVER:
			sprite.texture = TEX_LEVER_ON if is_active else TEX_LEVER_OFF
			sprite.offset = Vector2(0, 0)
			if prompt_label:
				prompt_label.text = "[E] Mechanism Active" if is_active else "[E] Pull Lever"
		Type.GATE:
			sprite.texture = TEX_GATE_OPEN if is_active else TEX_GATE_CLOSED
			sprite.offset = Vector2(0, -8) # 32x48 sprite offset so bottom aligns with tile
			if prompt_label:
				prompt_label.text = "[E] Enter Gate" if is_active else "Gate Locked"
		Type.TABLET:
			sprite.texture = TEX_TABLET
			sprite.offset = Vector2(0, 0)
			if prompt_label:
				prompt_label.text = "[E] Read Tablet"
		Type.NOTE:
			sprite.texture = TEX_NOTE
			sprite.offset = Vector2(0, 0)
			if prompt_label:
				prompt_label.text = "[E] Read Note"

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		current_interactor = body
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

		# If walking into an already opened gate as Wanderer, complete the level
		if type == Type.GATE and is_active and body.name == "Wanderer":
			interact(body)

func _on_body_exited(body: Node2D) -> void:
	if body == current_interactor:
		player_in_range = false
		current_interactor = null
		if prompt_label:
			prompt_label.visible = false
		var ui = _get_ui()
		if ui and ui.has_method("hide_message"):
			ui.hide_message()

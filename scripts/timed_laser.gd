extends Node2D

# ═════════════════════════════════════════════════════════════════════════════
# ECLIPSE — Timed Physical Red Laser
#
# Fully customizable in Godot's 2D Editor:
#   - Move and rotate this node in the 2D editor to set beam origin and direction.
#   - Adjust beam_length in Inspector to set length.
#   - Adjust timing cycle (inactive, warning, active) in Inspector.
#   - Sets safe_reset_pos in Inspector.
# ═════════════════════════════════════════════════════════════════════════════

enum State { INACTIVE, WARNING, ACTIVE }

@export var beam_length: float = 160.0:
	set(val):
		beam_length = val
		_setup_laser()

@export var inactive_duration: float = 2.5
@export var warning_duration: float = 0.75
@export var active_duration: float = 1.5
@export var safe_reset_pos: Vector2 = Vector2(80, 48)
@export var laser_audio_stream: AudioStream = null

@onready var laser_line: Line2D = $LaserLine
@onready var hazard_area: Area2D = $HazardArea
@onready var hazard_shape: CollisionShape2D = $HazardArea/CollisionShape2D
@onready var laser_audio: AudioStreamPlayer2D = get_node_or_null("LaserAudio")

var current_state: State = State.INACTIVE
var _state_timer: float = 0.0
var _warning_pulse: float = 0.0

func _ready() -> void:
	if not laser_line and has_node("LaserLine"):
		laser_line = $LaserLine
	if not hazard_area and has_node("HazardArea"):
		hazard_area = $HazardArea
	if not hazard_shape and has_node("HazardArea/CollisionShape2D"):
		hazard_shape = $HazardArea/CollisionShape2D
	if not laser_audio and has_node("LaserAudio"):
		laser_audio = $LaserAudio

	if laser_audio:
		laser_audio.bus = "SFX"
		laser_audio.volume_db = -18.0
		if laser_audio_stream:
			laser_audio.stream = laser_audio_stream

	if hazard_area:
		hazard_area.collision_layer = 0
		hazard_area.collision_mask = 4 # Layer 3: Wanderer_Body
		if not hazard_area.body_entered.is_connected(_on_body_entered):
			hazard_area.body_entered.connect(_on_body_entered)

	_setup_laser()
	_set_state(State.INACTIVE)

func _setup_laser() -> void:
	if not laser_line and has_node("LaserLine"):
		laser_line = $LaserLine
	if not hazard_shape and has_node("HazardArea/CollisionShape2D"):
		hazard_shape = $HazardArea/CollisionShape2D

	if laser_line:
		laser_line.points = PackedVector2Array([Vector2.ZERO, Vector2(beam_length, 0.0)])

	if hazard_shape:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(beam_length, 8.0)
		hazard_shape.shape = rect_shape
		hazard_shape.position = Vector2(beam_length * 0.5, 0.0)

func _physics_process(delta: float) -> void:
	_state_timer += delta

	match current_state:
		State.INACTIVE:
			if _state_timer >= inactive_duration:
				_set_state(State.WARNING)
		State.WARNING:
			_warning_pulse += delta * 12.0
			if laser_line:
				var alpha = 0.25 + sin(_warning_pulse) * 0.2
				laser_line.default_color = Color(1.0, 0.35, 0.2, clampf(alpha, 0.1, 0.5))
			if _state_timer >= warning_duration:
				_set_state(State.ACTIVE)
		State.ACTIVE:
			if _state_timer >= active_duration:
				_set_state(State.INACTIVE)

func _set_state(new_state: State) -> void:
	current_state = new_state
	_state_timer = 0.0

	match current_state:
		State.INACTIVE:
			if laser_line:
				laser_line.visible = false
			if hazard_shape:
				hazard_shape.disabled = true
			if laser_audio and laser_audio.playing:
				laser_audio.stop()
		State.WARNING:
			_warning_pulse = 0.0
			if laser_line:
				laser_line.visible = true
				laser_line.width = 2.0
				laser_line.default_color = Color(1.0, 0.35, 0.2, 0.35)
				laser_line.points = PackedVector2Array([Vector2.ZERO, Vector2(beam_length, 0.0)])
			if hazard_shape:
				hazard_shape.disabled = true
			if laser_audio and laser_audio.playing:
				laser_audio.stop()
		State.ACTIVE:
			if laser_line:
				laser_line.visible = true
				laser_line.width = 4.0
				laser_line.default_color = Color(1.0, 0.1, 0.15, 0.95)
				laser_line.points = PackedVector2Array([Vector2.ZERO, Vector2(beam_length, 0.0)])
			if hazard_shape:
				hazard_shape.disabled = false
				_check_instant_contact()
			if laser_audio and not laser_audio.playing and laser_audio.stream:
				laser_audio.play()

func _check_instant_contact() -> void:
	if not hazard_area:
		return
	for body in hazard_area.get_overlapping_bodies():
		if body.is_in_group("wanderer"):
			_on_body_entered(body)
			break

func _on_body_entered(body: Node2D) -> void:
	if current_state != State.ACTIVE:
		return
	if not body.is_in_group("wanderer"):
		return

	print("TIMED LASER HIT: Wanderer stepped into active red laser!")
	body.global_position = safe_reset_pos

	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("show_message"):
		ui.show_message("The searing laser burns your mortal flesh!", 2.5)

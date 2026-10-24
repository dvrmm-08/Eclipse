extends Node2D

@export var next_level_path: String = ""
@export var level_title: String = "LEVEL"
@export var level_subtitle: String = ""
@export var camera_follow_player: bool = false

@onready var grid: Node2D = $LevelGrid
@onready var shadow_collision: CollisionShape2D = get_node_or_null("Shadow/CollisionShape2D") as CollisionShape2D
@onready var wanderer: CharacterBody2D = $Wanderer
@onready var shadow: CharacterBody2D = $Shadow
@onready var camera: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UIOverlay

var eclipse_active: bool = false
var can_switch: bool = true
var is_completing: bool = false

func _ready() -> void:
	add_to_group("level")
	_setup_characters()

	if grid and grid.has_method("set_eclipse_mode"):
		grid.set_eclipse_mode(false)

	# Ensure cheerful exploration background music is playing
	if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
		var audio_mgr = get_tree().root.get_node("AudioManager")
		audio_mgr.play_gameplay_music(eclipse_active)

	# Center the fixed camera on the 640×384 room
	if camera:
		camera.global_position = Vector2(320, 192)

	# Show opening banner
	if ui and ui.has_method("show_banner"):
		ui.show_banner(level_title, level_subtitle)

func _setup_characters() -> void:
	if wanderer:
		wanderer.add_to_group("wanderer")
		wanderer.is_controlled = true
		wanderer.velocity = Vector2.ZERO

	if shadow:
		shadow.add_to_group("shadow")
		shadow.is_controlled = false
		shadow.visible = false
		shadow.velocity = Vector2.ZERO

	if shadow_collision:
		shadow_collision.disabled = true

func _process(delta: float) -> void:
	if camera:
		if camera_follow_player:
			var target = shadow if (eclipse_active and shadow.visible) else wanderer
			if target:
				camera.global_position = camera.global_position.lerp(target.global_position, 8.0 * delta)
		else:
			# Keep whole 640×384 room centered — fixed camera
			camera.global_position = Vector2(320, 192)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_eclipse") and can_switch and not is_completing:
		toggle_dimension()
	elif event.is_action_pressed("restart") and not is_completing:
		if is_inside_tree() and get_tree():
			get_tree().reload_current_scene()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
				var audio_mgr = get_tree().root.get_node("AudioManager")
				var muted = false
				if audio_mgr.has_method("toggle_music_mute"):
					muted = audio_mgr.toggle_music_mute()
				else:
					muted = audio_mgr.toggle_mute()
				if ui and ui.has_method("show_message"):
					ui.show_message("Music: " + ("MUTED" if muted else "UNMUTED"), 1.5)
		elif event.keycode == KEY_ESCAPE:
			if is_inside_tree() and get_tree():
				get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func toggle_dimension() -> void:
	if not wanderer or not shadow:
		return

	# If Eclipse is active, dismiss the Shadow.
	if eclipse_active:
		eclipse_active = false

		shadow.is_controlled = false
		shadow.velocity = Vector2.ZERO
		shadow.visible = false

		if shadow_collision:
			shadow_collision.set_deferred("disabled", true)

		wanderer.is_controlled = true
		wanderer.velocity = Vector2.ZERO

		# Sound for returning to Wanderer
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			var audio_mgr = get_tree().root.get_node("AudioManager")
			audio_mgr.play_return_wanderer_sfx()

		print("NORMAL MODE: Shadow dismissed")

	# Otherwise, summon the Shadow at the Wanderer's current position.
	else:
		eclipse_active = true

		shadow.global_position = wanderer.global_position
		shadow.velocity = Vector2.ZERO
		shadow.visible = true

		if shadow_collision:
			shadow_collision.set_deferred("disabled", false)

		wanderer.is_controlled = false
		wanderer.velocity = Vector2.ZERO
		shadow.is_controlled = true

		# Sound for summoning the Shadow
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			var audio_mgr = get_tree().root.get_node("AudioManager")
			audio_mgr.play_summon_shadow_sfx()

		print("ECLIPSE MODE: Shadow summoned")

	# Update the world and interface.
	if grid and grid.has_method("set_eclipse_mode"):
		grid.set_eclipse_mode(eclipse_active)

	if ui and ui.has_method("update_dimension"):
		ui.update_dimension(eclipse_active)

	# Dynamic music crossfade between cheerful Normal and ominous Shadow tracks
	if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
		var audio_mgr = get_tree().root.get_node("AudioManager")
		audio_mgr.play_gameplay_music(eclipse_active, 0.8)

func complete_level() -> void:
	if is_completing:
		return
	is_completing = true
	print("Level completed! Transitioning to: ", next_level_path)

	if ui and ui.has_method("show_banner"):
		ui.show_banner("GATE UNLOCKED", "Entering the depths...")

	wanderer.is_controlled = false
	shadow.is_controlled = false

	if is_inside_tree() and get_tree():
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			if next_level_path != "":
				get_tree().change_scene_to_file(next_level_path)
			else:
				print("Level complete — no next level.")
		)

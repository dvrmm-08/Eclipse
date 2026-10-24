extends Node2D

const MAP_LAYOUT: Array[String] = [
	"####################",
	"#...:::...G...::...#",
	"#..::::... ...::...#",
	"#,:::~====~:::....#",
	"#,:::~~~~~~:::::...#",
	"#,:::~~~~~~::::::::#",
	"#,:::~~~~~~::::::::#",
	"#,:::~====~::::::::#",
	"#,:::......::::::::#",
	"#,,,,:::::.........#",
	"#,,,,:::::.........#",
	"####################"
]

@onready var grid: Node2D = $LevelGrid
@onready var wanderer: CharacterBody2D = $Wanderer
@onready var shadow: CharacterBody2D = $Shadow
@onready var camera: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UIOverlay

func _ready() -> void:
	if grid:
		grid.build_map(MAP_LAYOUT)
		grid.set_eclipse_mode(true)
		
	wanderer.is_controlled = true
	wanderer.position = Vector2(160, 260)
	
	shadow.visible = true
	shadow.is_controlled = false
	shadow.position = Vector2(480, 140)
	
	camera.position = wanderer.position
	
	if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
		var audio_mgr = get_tree().root.get_node("AudioManager")
		audio_mgr.play_music()

	if ui and ui.has_method("show_banner"):
		ui.show_banner("EPILOGUE", "THE REFLECTION")
	if ui and ui.has_method("show_message"):
		ui.show_message("You escaped through the gate... but your shadow moves in reverse. [R] Restart | [ESC] Title", 15.0)

func _physics_process(delta: float) -> void:
	if camera and wanderer:
		camera.global_position = camera.global_position.lerp(wanderer.global_position, 6.0 * delta)
		
	# Inverted movement: Shadow mirrors Wanderer in the wrong direction!
	if wanderer and shadow:
		shadow.velocity = -wanderer.velocity
		shadow.move_and_slide()
		
		if wanderer.velocity.x < -0.1:
			shadow.get_node("Sprite2D").flip_h = false
		elif wanderer.velocity.x > 0.1:
			shadow.get_node("Sprite2D").flip_h = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().change_scene_to_file("res://scenes/level_1.tscn")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		elif event.keycode == KEY_M:
			if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
				var audio_mgr = get_tree().root.get_node("AudioManager")
				var muted = audio_mgr.toggle_mute()
				if ui and ui.has_method("show_message"):
					ui.show_message("Audio: " + ("MUTED" if muted else "UNMUTED"), 1.5)

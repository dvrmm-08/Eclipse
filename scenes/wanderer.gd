extends CharacterBody2D

@export var speed: float = 130.0
@export var is_controlled: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var input_disabled: bool = false
var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	if not is_controlled or input_disabled:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0:
		facing_direction = direction
		if direction.x < -0.1:
			sprite.flip_h = true
		elif direction.x > 0.1:
			sprite.flip_h = false

	velocity = direction * speed
	move_and_slide()

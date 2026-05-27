extends CharacterBody2D
@export var speed: float = 150.0
@onready var animations = $AnimatedSprite2D 
func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("izq", "der", "arr", "abb")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animations.play("walk_right")
			else:
				animations.play("walk_left")
		else:
			if direction.y > 0:
				animations.play("walk_down")
			else:
				animations.play("walk_up")
	else:
		animations.stop()
		animations.frame = 0

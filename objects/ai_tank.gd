extends CharacterBody2D
class_name AITank

@export var speed := 300.0
@export var rotation_speed := 2.5

func apply_ai_action(action: Vector2, delta: float) -> void:
	print("Applying AI action:", action)
	rotation += action.y * rotation_speed * delta
	var dir := Vector2.RIGHT.rotated(rotation)
	velocity = dir * (action.x * speed)
	move_and_slide()

extends CharacterBody2D
class_name AITank

var speed = 200
var angularSpeed = PI
var turn_direction := 1.0
var move_dir := 1.0


func _process(delta: float) -> void:
	# Rotate the tank
	rotation += angularSpeed * turn_direction * delta
	# Apply velocity based on rotation
	velocity = Vector2.UP.rotated(rotation) * (speed * move_dir)
	# Use move_and_slide for proper collision
	move_and_slide()

func setTurn(turn: float) -> void:
	if turn > 0.0:
		turn_direction = 1.0
	elif turn < 0.0:
		turn_direction = -0.5

func setDirection(move: float):
	if move > 0.0:
		move_dir = 1.0
	elif move < 0.0:
		move_dir = -0.5 

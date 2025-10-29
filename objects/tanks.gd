extends CharacterBody2D


var speed = 200
var angularSpeed = PI


func _process(delta: float) -> void:
	var turn_direction := 0.0
	if Input.is_action_pressed("ui_left"):
		turn_direction = -1.0
	elif Input.is_action_pressed("ui_right"):
		turn_direction = 1.0

	# Rotate the tank
	rotation += angularSpeed * turn_direction * delta

	# Forward / backward movement
	var move_dir := 0.0
	if Input.is_action_pressed("ui_up"):
		move_dir = 1.0
	elif Input.is_action_pressed("ui_down"):
		move_dir = -0.5  # Half speed for reverse

	# Apply velocity based on rotation
	velocity = Vector2.UP.rotated(rotation) * (speed * move_dir)

	# Use move_and_slide for proper collision
	move_and_slide()

extends Area2D
signal goal_reached

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "AITank":
		emit_signal("goal_reached")
		print("Goal reached by:", body.name)

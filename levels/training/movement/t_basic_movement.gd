extends Node2D

@onready var tank := $AITank      # adjust path if your node is named differently
@onready var goal := $Goal
@onready var conn := $PythonConnector

var arena_w := 1.0
var arena_h := 1.0

func _ready() -> void:
	var r := get_viewport_rect().size
	arena_w = max(r.x, 1.0)
	arena_h = max(r.y, 1.0)
	print("Arena ready:", arena_w, arena_h)
	if tank == null:
		push_error("TrainingArena: AITank node not found! Children: %s" % str(get_children()))
	if goal == null:
		push_error("TrainingArena: Goal node not found! Children: %s" % str(get_children()))
	if conn == null:
		push_error("TrainingArena: PythonConnector not found! Children: %s" % str(get_children()))

func _physics_process(delta: float) -> void:
	if tank == null or conn == null:
		return

	# 1️⃣ Build & send current state
	var state := {
		"tank_x": tank.position.x / arena_w,
		"tank_y": tank.position.y / arena_h,
		"goal_x": goal.position.x / arena_w,
		"goal_y": goal.position.y / arena_h
	}
	conn.send_state(state)
	# print("Sent state:", state)

	# 2️⃣ Poll & get next action
	conn.poll()
	var action: Vector2 = conn.pop_action_or_default(Vector2.ZERO)
	print("Action from connector:", action)

	# 3️⃣ Apply to tank
	tank.apply_ai_action(action, delta)

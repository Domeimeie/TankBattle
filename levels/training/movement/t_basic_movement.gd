extends Node2D

@onready var tank = $AITank      # adjust path if your node is named differently
@onready var goal = $Goal
@onready var conn = $PythonConnector

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

func sendArenaParams() -> String:
	 # Get positions (use global_position if these are Node2D)
	var tank_pos = tank.global_position
	var goal_pos = goal.global_position
	var data := {
		"arena": {
			"width": arena_w,
			"height": arena_h
		},
		"tank": {
			"x": tank_pos.x,
			"y": tank_pos.y
		},
		"goal": {
			"x": goal_pos.x,
			"y": goal_pos.y
		}
	}

	var json := JSON.stringify(data)
	return json

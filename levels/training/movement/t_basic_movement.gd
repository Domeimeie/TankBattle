extends Node2D

@onready var tank = $AITank      # adjust path if your node is named differently
@onready var goal = $Goal
@onready var conn = $PythonConnector

var arena_w := 1.0
var arena_h := 1.0

var prev_dist := 0.0
var last_reward := 0.0
var done := false


func _ready() -> void:
	var r = get_viewport_rect().size
	arena_w = max(r.x, 1.0)
	arena_h = max(r.y, 1.0)
	print("Arena ready:", arena_w, arena_h)
	if tank == null:
		push_error("TrainingArena: AITank node not found! Children: %s" % str(get_children()))
	if goal == null:
		push_error("TrainingArena: Goal node not found! Children: %s" % str(get_children()))
	if conn == null:
		push_error("TrainingArena: PythonConnector not found! Children: %s" % str(get_children()))

	_resetEpisode()


func _resetEpisode() -> void:
	if tank == null or goal == null:
		return

	var tank_pos = tank.global_position
	var goal_pos = goal.global_position
	prev_dist = tank_pos.distance_to(goal_pos)
	last_reward = 0.0
	done = false
	print("Episode reset, initial distance:", prev_dist)


func _updateReward() -> void:
	if done:
		# Episode already ended, no more reward this step
		last_reward = 0.0
		return

	if tank == null or goal == null:
		last_reward = 0.0
		return

	var tank_pos = tank.global_position
	var goal_pos = goal.global_position

	var dist_now = tank_pos.distance_to(goal_pos)
	var dist_change = prev_dist - dist_now

	# Base reward:
	#  - positive if we move closer
	#  - small negative each step to encourage faster solutions
	var r = 0.1 * dist_change - 0.01

	# Goal reached?
	var goal_radius = 20.0  # tweak as needed
	if dist_now < goal_radius:
		r += 1.0
		done = true
		print("Goal reached!")

	# TODO: add extra penalties for collisions / out of bounds if needed

	last_reward = r
	prev_dist = dist_now


func sendArenaParams() -> String:
	# Update reward before sending state
	_updateReward()

	# Get positions (use global_position since this is Node2D)
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
		},
		"reward": last_reward,
		"done": done
	}

	var json = JSON.stringify(data)
	return json

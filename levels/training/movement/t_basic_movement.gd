extends Node2D

@onready var tank = $AITank
@onready var goal = $Goal
@onready var conn = $PythonConnector

var arena_w := 1.0
var arena_h := 1.0

var prev_dist := 0.0
var last_reward := 0.0
var done := false

var step_count := 0
const MAX_STEPS := 300  

var goal_hit_this_step := false


func _ready() -> void:
	randomize()

	var r := get_viewport_rect().size
	arena_w = max(r.x, 1.0)
	arena_h = max(r.y, 1.0)
	$Goal.goal_reached.connect(_on_goal_collision)
	
	if tank == null:
		push_error("TrainingArena: AITank node not found! Children: %s" % str(get_children()))
	if goal == null:
		push_error("TrainingArena: Goal node not found! Children: %s" % str(get_children()))
	if conn == null:
		push_error("TrainingArena: PythonConnector not found! Children: %s" % str(get_children()))

	_reset_episode()


func _on_goal_collision() -> void:
	print("Arena received goal collision")
	goal_hit_this_step = true

func _reset_episode() -> void:
	if tank == null or goal == null:
		return

	var margin := 50.0

	# Randomize tank and goal positions inside the arena
	var tank_pos := Vector2(
		randf_range(margin, arena_w - margin),
		randf_range(margin, arena_h - margin)
	)
	var goal_pos := Vector2(
		randf_range(margin, arena_w - margin),
		randf_range(margin, arena_h - margin)
	)

	tank.global_position = tank_pos
	goal.global_position = goal_pos

	# Randomize tank orientation
	tank.rotation = randf_range(-PI, PI)

	prev_dist = tank_pos.distance_to(goal_pos)
	last_reward = 0.0
	done = false
	step_count = 0
	goal_hit_this_step = false

	print("Episode reset, tank:", tank.global_position, "goal:", goal.global_position, "dist:", prev_dist)


func _update_reward_and_done() -> void:
	if tank == null or goal == null:
		last_reward = 0.0
		return

	# already finished this step -> no more reward
	if done:
		last_reward = 0.0
		return

	var tank_pos = tank.global_position
	var goal_pos = goal.global_position

	var dist_now = tank_pos.distance_to(goal_pos)
	var dist_change = prev_dist - dist_now

	# Base reward:
	#  + getting closer to goal
	#  - small time penalty every tick
	var r = 0.1 * dist_change - 0.01

	# Goal reached?
	if goal_hit_this_step and not done:
		r += 1.0  # completion bonus
		done = true
		#print("Goal reached via collision!")
		
	#var goal_radius := 20.0
	#if dist_now < goal_radius:
	#	r += 1.0
	#	done = true

	# Episode timeout
	step_count += 1
	if step_count >= MAX_STEPS and not done:
		r -= 0.5  # extra penalty for timing out
		done = true
		print("Episode timeout at step", step_count, "dist =", dist_now)

	last_reward = r
	prev_dist = dist_now


func sendArenaParams() -> String:
	# Update reward/done for this step
	_update_reward_and_done()

	var tank_pos = tank.global_position
	var goal_pos = goal.global_position

	var current_reward := last_reward
	var current_done := done

	var data := {
		"arena": {
			"width": arena_w,
			"height": arena_h
		},
		"tank": {
			"x": tank_pos.x,
			"y": tank_pos.y,
			"rot": tank.rotation   # orientation in radians
		},
		"goal": {
			"x": goal_pos.x,
			"y": goal_pos.y
		},
		"reward": current_reward,
		"done": current_done
	}

	var json := JSON.stringify(data)

	# If this state ended the episode, immediately prepare the next one
	if current_done:
		_reset_episode()

	return json

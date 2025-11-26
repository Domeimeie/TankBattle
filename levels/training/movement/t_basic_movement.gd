extends Node2D

@onready var tank = $AITank
@onready var goal = $Goal
@onready var conn = $PythonConnector

var arena_w := 1.0
var arena_h := 1.0

# Training / reward system
var start_tank_pos := Vector2.ZERO
var start_goal_pos := Vector2.ZERO
var last_distance := 0.0


func _ready() -> void:
	var r := get_viewport_rect().size
	arena_w = max(r.x, 1.0)
	arena_h = max(r.y, 1.0)

	_reset_episode()


func _process(delta: float) -> void:
	_check_episode()


func _check_episode():
	var dist = tank.global_position.distance_to(goal.global_position)

	# Reward = improvement in distance
	var reward = (last_distance - dist) / arena_w    # normalized reward
	last_distance = dist

	var done := false

	# If tank reached goal
	if dist < 20.0:
		reward += 1.0         # big positive reward
		done = true

	# If tank leaves arena
	if tank.global_position.x < 0 or tank.global_position.x > arena_w \
	or tank.global_position.y < 0 or tank.global_position.y > arena_h:
		reward -= 1.0
		done = true

	# Send to Python
	conn.send_reward_and_done(reward, done)

	# Reset if needed
	if done:
		_reset_episode()


func _reset_episode():
	# Randomize start locations (this is very important for training)
	start_tank_pos = Vector2(randf_range(100, arena_w-100), randf_range(100, arena_h-100))
	start_goal_pos = Vector2(randf_range(100, arena_w-100), randf_range(100, arena_h-100))

	tank.global_position = start_tank_pos
	goal.global_position = start_goal_pos

	last_distance = tank.global_position.distance_to(goal.global_position)
	print("Episode reset, initial distance:", last_distance)


func sendArenaParams() -> String:
	var tank_pos = tank.global_position
	var goal_pos = goal.global_position

	var data := {
		"arena": { 
			"width": arena_w, 
			"height": arena_h 
		},
		"tank":  { 
			"x": tank_pos.x, 
			"y": tank_pos.y,
			"rot": tank.rotation      # NEW: orientation in radians
		},
		"goal":  { 
			"x": goal_pos.x, 
			"y": goal_pos.y 
		}
	}

	return JSON.stringify(data)


# =========================================
# NEW: function PythonConnector will call
# =========================================
func send_reward_and_done(reward: float, done: bool):
	if conn.client:
		var msg := {
			"reward": reward,
			"done": done
		}
		conn.client.put_data(JSON.stringify(msg).to_utf8_buffer())

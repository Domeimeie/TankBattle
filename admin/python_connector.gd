extends Node

var server := TCPServer.new()
var client: StreamPeerTCP

const DEFAULT_PORT := 5000
var port: int = DEFAULT_PORT

const SEND_INTERVAL := 0.2  # 5 times per second
var send_timer := 0.0

@onready var arena = get_parent()                     # TrainingArena
@onready var tank = get_parent().get_node("AITank")   # AITank node

# NEW: store latest reward/done passed from the arena
var last_reward: float = 0.0
var last_done: bool = false


func _ready() -> void:
	_read_port_from_env()

	if server.listen(port) != OK:
		push_error("PythonConnector: Could not start server on port %d." % port)
	else:
		print("PythonConnector: Server listening on port %d" % port)


func _read_port_from_env() -> void:
	# Read port from environment variable TANK_PORT (set by run_envs.py)
	var env_port := OS.get_environment("TANK_PORT")
	if env_port != "":
		var p := int(env_port)
		if p > 0:
			port = p
			print("PythonConnector: Using port from env TANK_PORT =", port)
	else:
		print("PythonConnector: No TANK_PORT env var, using default:", port)


func _process(delta: float) -> void:
	# Accept a client
	if client == null and server.is_connection_available():
		client = server.take_connection()
		print("PythonConnector: Client connected!")

	if client:
		# Handle disconnect
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("PythonConnector: Client disconnected.")
			client = null
			return

		# --------- RECEIVE FROM PYTHON (ACTIONS) ----------
		var available := client.get_available_bytes()
		if available > 0:
			var raw := client.get_utf8_string(available)
			var obj = JSON.parse_string(raw)
			if obj == null:
				print("PythonConnector: Invalid JSON from Python:", raw)
			else:
				_handle_python_message(obj)
		# --------------------------------------------------

		# --------- SEND STATE TO PYTHON (5x/sec) ----------
		send_timer += delta
		if send_timer >= SEND_INTERVAL:
			send_timer = 0.0

			var arena_json_str: String = arena.sendArenaParams()

			# NEW: inject latest reward/done from arena into the JSON
			var parsed = JSON.parse_string(arena_json_str)
			if typeof(parsed) == TYPE_DICTIONARY:
				parsed["reward"] = last_reward
				parsed["done"] = last_done
				arena_json_str = JSON.stringify(parsed)

			client.put_data(arena_json_str.to_utf8_buffer())
		# --------------------------------------------------


func _handle_python_message(obj) -> void:
	if typeof(obj) != TYPE_DICTIONARY:
		return
	if not obj.has("action"):
		return

	var action = obj["action"]
	if typeof(action) != TYPE_DICTIONARY:
		return

	if tank == null:
		return

	var turn := 0.0
	var throttle := 0.0

	if action.has("turn"):
		turn = float(action["turn"])
	if action.has("throttle"):
		throttle = float(action["throttle"])

	tank.setTurn(turn)
	tank.setDirection(throttle)


# NEW: this is what your arena calls from _check_episode()
func send_reward_and_done(reward: float, done: bool) -> void:
	last_reward = reward
	last_done = done

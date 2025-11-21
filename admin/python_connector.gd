extends Node

var server := TCPServer.new()
var client: StreamPeerTCP

const PORT := 5000
const SEND_INTERVAL := 0.5  # 5 times per second

@onready var arena = get_parent()              # TrainingArena
@onready var tank = get_parent().get_node("AITank")  # AITank node

var send_timer := 0.0


func _ready() -> void:
	if server.listen(PORT) != OK:
		push_error("Could not start server.")
	else:
		print("Server listening on port %d" % PORT)


func _process(delta: float) -> void:
	# Accept a client
	if client == null and server.is_connection_available():
		client = server.take_connection()
		print("Client connected!")

	if client:
		# Handle disconnect
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Client disconnected.")
			client = null
			return

		# --------- RECEIVE FROM PYTHON (ACTIONS) ----------
		var available := client.get_available_bytes()
		if available > 0:
			var raw := client.get_utf8_string(available)
			var obj = JSON.parse_string(raw)
			if obj == null:
				print("Invalid JSON received from Python:", raw)
			else:
				_handle_python_message(obj)
		# --------------------------------------------------

		# --------- SEND STATE TO PYTHON (5x/sec) ----------
		send_timer += delta
		if send_timer >= SEND_INTERVAL:
			send_timer = 0.0

			var arena_json_str: String = arena.sendArenaParams()
			client.put_data(arena_json_str.to_utf8_buffer())
		# --------------------------------------------------


func _handle_python_message(obj) -> void:
	# Expecting something like:
	# {
	#   "value": ...,
	#   "action": {
	#       "turn": -1.0..1.0,
	#       "throttle": 0.0..1.0
	#   },
	#   "debug": { ... }
	# }
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

	# Call your AITank control methods
	tank.setTurn(turn)
	tank.setDirection(throttle)

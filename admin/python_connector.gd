extends Node

var server := TCPServer.new()
var client: StreamPeerTCP

const PORT := 5000
const SEND_INTERVAL := 0.5    # 5 times per second (1 / 0.2)

@onready var arena := get_parent()

var send_timer: float = 0.0

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
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Client disconnected.")
			client = null
			return

		# Optional: read messages from Python
		var available := client.get_available_bytes()
		if available > 0:
			var raw := client.get_utf8_string(available)
			var obj = JSON.parse_string(raw)
			print("Received:", obj)

		# ----------------------------
		# SEND EVERY 0.2 SECONDS (5 FPS)
		# ----------------------------
		send_timer += delta
		if send_timer >= SEND_INTERVAL:
			send_timer = 0.0

			var arena_json_str: String = arena.sendArenaParams()
			client.put_data(arena_json_str.to_utf8_buffer())

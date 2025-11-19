extends Node

var server := TCPServer.new()
var client : StreamPeerTCP

const PORT := 5000

func _ready() -> void:
	if server.listen(PORT) != OK:
		push_error("Could not start server.")
	else:
		print("Server listening on port %d" % PORT)


func _process(_delta: float) -> void:
	# Accept a single client
	if client == null and server.is_connection_available():
		client = server.take_connection()
		print("Client connected!")

	if client:
		# If disconnected, reset
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Client disconnected.")
			client = null
			return

		# Read incoming data
		var available := client.get_available_bytes()
		if available > 0:
			var raw := client.get_utf8_string(available)
			var obj = JSON.parse_string(raw)
			if obj == null:
				print("Invalid JSON received:", raw)
				return

			print("Received JSON:", obj)

			# Send JSON back
			var response := {"ok": true, "received": obj}
			_send_json(response)


func _send_json(data: Dictionary) -> void:
	var s := JSON.stringify(data)
	client.put_data(s.to_utf8_buffer())

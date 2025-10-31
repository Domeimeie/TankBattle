extends Node
class_name PythonConnector

var tcp := StreamPeerTCP.new()
var packet := PacketPeerStream.new()
var connected := false
var recv_buf := ""
var pending_actions: Array = []

@export var host := "127.0.0.1"
@export var port := 5555

func _ready() -> void:
	var err := tcp.connect_to_host(host, port)
	if err != OK:
		push_error("PythonConnector: failed to connect (%s)" % err)
		return

	connected = true
	packet.stream_peer = tcp
	print("PythonConnector: Connected to %s:%d" % [host, port])

# --- Send state dictionary as JSON ---
func send_state(state: Dictionary) -> void:
	if not connected:
		return
	# Build plain JSON line
	var json_line := JSON.stringify(state)
	# Write exactly that text + ASCII newline
	var bytes := (json_line + "\n").to_utf8_buffer()
	tcp.put_data(bytes)
	tcp.poll()  # push it out immediately
	print("Sent to Python:", json_line)

# --- Poll incoming data from Python ---
func poll() -> void:
	if not connected: return
	while tcp.get_available_bytes() > 0:
		recv_buf += tcp.get_utf8_string(tcp.get_available_bytes())
		var lines := Array(recv_buf.split("\n", false))
		recv_buf = ""
		if lines.size() > 0:
			recv_buf = lines.pop_back()  # keep incomplete line
		for line in lines:
			if line.is_empty():
				continue
			var parsed: Variant = JSON.parse_string(line)
			if parsed is Array and parsed.size() == 2:
				print("Received action from Python:", parsed)
				pending_actions.append(Vector2(parsed[0], parsed[1]))
			else:
				push_warning("PythonConnector: bad line: %s" % line)

func pop_action_or_default(default_action := Vector2.ZERO) -> Vector2:
	if pending_actions.size() > 0:
		return pending_actions.pop_front()
	return default_action

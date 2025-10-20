extends Control

func _ready():
	# Optional: listen for connection signals from the Network autoload
	if Engine.has_singleton("Network"):
		Network.connected.connect(_on_network_connected)

func _on_server_pressed():
	# Start the host (server + local player)
	Network.start_host()
	# Print helpful join instructions to console; the UI shows them as well
	print("Host started. To allow other laptops on the same LAN to join, find your LAN IP (Windows: `ipconfig`) and share it with them, along with port %d." % Network.DEFAULT_PORT)

func _on_network_connected(success, reason):
	if success:
		# Move to lobby where the MultiplayerSpawner can spawn the host player
		var lobby_path = "res://scenes/Lobby.tscn"
		if ResourceLoader.exists(lobby_path):
			get_tree().change_scene_to_file(lobby_path)
		else:
			print("Lobby scene not found at %s, but host started: %s" % [lobby_path, reason])
	else:
		push_error("Failed to start host: %s" % reason)

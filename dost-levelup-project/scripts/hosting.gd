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
		if ResourceLoader.exists("res://scenes/lobby.tscn"):
			get_tree().change_scene("res://scenes/lobby.tscn")
		else:
			print("Lobby scene not found, but host started: %s" % reason)
	else:
		push_error("Failed to start host: %s" % reason)

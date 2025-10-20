extends Control

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var instructions_button = $VBoxContainer/InstructionsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var status_label = $StatusLabel
@onready var ip_label = $IPDisplay/IPLabel
@onready var instructions_panel = $InstructionsPanel
@onready var close_instructions_button = $InstructionsPanel/CloseInstructionsButton

func _ready():
	# Connect button signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_instructions_button.pressed.connect(_on_close_instructions_pressed)
	
	# Connect to network signals
	Network.connected.connect(_on_network_connected)
	Network.player_joined.connect(_on_player_joined)
	Network.player_left.connect(_on_player_left)
	
	# Get and display local IP address
	_display_local_ip()
	
	status_label.text = "Ready to play!"

func _on_instructions_pressed():
	instructions_panel.visible = true

func _on_close_instructions_pressed():
	instructions_panel.visible = false

func _display_local_ip():
	var ip_addresses = IP.get_local_addresses()
	var local_ip = "localhost"
	
	print("All IP addresses: ", ip_addresses)
	
	# Find the first non-localhost IP address
	for ip in ip_addresses:
		if ip != "127.0.0.1" and ip != "::1" and not ip.begins_with("169.254") and not ip.begins_with("fe80"):
			local_ip = ip
			break
	
	ip_label.text = "Your IP: " + local_ip
	print("Using IP: ", local_ip)
	
	# Also try to get the primary IP
	var primary_ip = _get_primary_ip()
	if primary_ip != "":
		ip_label.text = "Your IP: " + primary_ip
		print("Primary IP: ", primary_ip)

func _get_primary_ip() -> String:
	# Try to get the primary network interface IP
	var ip_addresses = IP.get_local_addresses()
	
	# Look for common LAN IP ranges
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	
	# Fallback to first non-localhost IP
	for ip in ip_addresses:
		if ip != "127.0.0.1" and ip != "::1":
			return ip
	
	return ""

func _on_host_pressed():
	status_label.text = "Starting host..."
	Network.start_host()

func _on_join_pressed():
	# Switch to join scene
	get_tree().change_scene_to_file("res://scenes/JoinGame.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_network_connected(success: bool, reason: String):
	if success:
		if reason == "host_started":
			status_label.text = "Host started! Waiting for players..."
			# Switch to lobby scene
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
		elif reason == "connected":
			status_label.text = "Connected to host!"
			# Switch to lobby scene
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Connection failed: " + reason

func _on_player_joined(player_id: int):
	print("Player joined: ", player_id)

func _on_player_left(player_id: int):
	print("Player left: ", player_id)

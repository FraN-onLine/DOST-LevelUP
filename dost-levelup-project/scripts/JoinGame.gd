extends Control

@onready var ip_input = $VBoxContainer/IPInput
@onready var connect_button = $VBoxContainer/HBoxContainer/ConnectButton
@onready var back_button = $VBoxContainer/HBoxContainer/BackButton
@onready var status_label = $StatusLabel

func _ready():
	# Connect button signals
	connect_button.pressed.connect(_on_connect_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect to network signals
	Network.connected.connect(_on_network_connected)
	
	# Allow Enter key to connect
	ip_input.text_submitted.connect(_on_ip_submitted)
	
	status_label.text = "Enter host IP address"

func _on_connect_pressed():
	_attempt_connection()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_ip_submitted(text: String):
	_attempt_connection()

func _attempt_connection():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Please enter an IP address"
		return
	
	status_label.text = "Connecting to " + ip + "..."
	connect_button.disabled = true
	
	Network.join_host(ip)

func _on_network_connected(success: bool, reason: String):
	connect_button.disabled = false
	
	if success:
		status_label.text = "Connected successfully!"
		# Switch to lobby scene
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Connection failed: " + reason

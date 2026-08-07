extends Control

@onready var host_button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button = $CenterContainer/VBoxContainer/JoinButton
@onready var almanac_button = $CenterContainer/VBoxContainer/AlmanacButton
@onready var instructions_button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var status_label = $StatusLabel
@onready var ip_label = $IPDisplay/IPLabel
@onready var instructions_panel = $InstructionsPanel
@onready var close_instructions_button = $InstructionsPanel/CloseInstructionsButton

func _ready():
	# Connect button signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	almanac_button.pressed.connect(_on_almanac_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_instructions_button.pressed.connect(_on_close_instructions_pressed)
	
	# Connect to network signals
	Network.connected.connect(_on_network_connected)
	
	status_label.text = "Ready to play!"

func _on_instructions_pressed():
	instructions_panel.visible = true

func _on_close_instructions_pressed():
	instructions_panel.visible = false

func _on_host_pressed():
	# Go to the hosting screen where the player sets their name
	get_tree().change_scene_to_file("res://scenes/Hosting.tscn")

func _on_join_pressed():
	# Switch to join scene which auto-discovers hosts on LAN
	get_tree().change_scene_to_file("res://scenes/JoinGame.tscn")

func _on_almanac_pressed():
	# Open the almanac to view all cards
	get_tree().change_scene_to_file("res://scenes/Almanac.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_network_connected(success: bool, reason: String):
	if success:
		if reason == "connected":
			status_label.text = "Connected to host!"
			# Switch to lobby scene
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Connection failed: " + reason

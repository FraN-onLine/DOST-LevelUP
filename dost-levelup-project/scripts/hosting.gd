extends Control

@onready var name_input = $CenterContainer/VBoxContainer/NameInput
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var status_label = $StatusLabel

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	
	# Connect to network signals
	Network.connected.connect(_on_network_connected)
	
	# Focus on the name input so the user can type immediately
	name_input.grab_focus()
	
	# Pre-fill with any existing host name
	name_input.text = Network.host_name if Network.host_name != "Host" else ""
	if name_input.text.is_empty():
		name_input.text = "Player"
	
	status_label.text = "Enter your name to host a game"

func _on_start_pressed():
	_start_hosting()

func _on_name_submitted(_text: String):
	_start_hosting()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _start_hosting():
	var name = name_input.text.strip_edges()
	if name.is_empty():
		status_label.text = "Please enter a name first"
		return
	
	# Set the host name on the Network autoload
	Network.set_host_name(name)
	
	status_label.text = "Starting host as '%s'..." % name
	start_button.disabled = true
	
	# Start the host - auto uses the local machine's IP on the LAN
	Network.start_host()

func _on_network_connected(success: bool, reason: String):
	start_button.disabled = false
	
	if success and reason == "host_started":
		status_label.text = "Host started! Waiting for players..."
		# Move to lobby
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Failed to start host: " + reason

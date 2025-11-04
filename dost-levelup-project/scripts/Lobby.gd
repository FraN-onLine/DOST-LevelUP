extends Control

@onready var player_list_vbox = $VBoxContainer/PlayerList/PlayerListVBox
@onready var name_input = $VBoxContainer/NameChangeContainer/NameInput
@onready var change_name_button = $VBoxContainer/NameChangeContainer/ChangeNameButton
@onready var start_game_button = $VBoxContainer/ButtonContainer/StartGameButton
@onready var leave_button = $VBoxContainer/ButtonContainer/LeaveButton
@onready var status_label = $StatusLabel
@onready var ip_label = $IPLabel

var connected_players = {}
var is_host = false

func _ready():
	# Connect button signals
	start_game_button.pressed.connect(_on_start_game_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	change_name_button.pressed.connect(_on_change_name_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	
	# Connect to network signals
	Network.player_joined.connect(_on_player_joined)
	Network.player_left.connect(_on_player_left)
	Network.player_list_updated.connect(_on_player_list_updated)
	
	# Check if we're the host
	is_host = multiplayer.is_server()
	
	if is_host:
		status_label.text = "You are the host. Waiting for players..."
		# Display IP address for host
		_display_host_ip()
	else:
		status_label.text = "Connected to host. Waiting for game to start..."
		start_game_button.visible = false
		# Hide IP label for clients
		if ip_label:
			ip_label.visible = false
	
	# Request current player list from server
	if is_host:
		# Re-broadcast from server to ensure lobby clients get the latest list
		Network.broadcast_player_list()
		connected_players = Network.players.duplicate()
		_update_player_list()
		# Prefill name input with host's current authoritative name
		var my_id = multiplayer.get_unique_id()
		if my_id in connected_players:
			name_input.text = str(connected_players[my_id])
	else:
		# Ask server for current list
		Network.rpc_id(1, "request_player_list")
	
	_update_player_list()

func _on_start_game_pressed():
	if is_host and connected_players.size() >= 2:
		# Ask the server to start the game (authoritative). Network.start_game will deal and
		# perform the scene-change handshake so all clients are transitioned correctly.
		Network.start_game()

func _on_leave_pressed():
	if is_host:
		Network.stop_host()
	else:
		Network.leave_host()
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_player_joined(player_id: int):
	print("Player joined lobby: ", player_id)
	_add_player_to_list(player_id, "Player " + str(player_id))
	_update_player_list()

func _on_player_left(player_id: int):
	print("Player left lobby: ", player_id)
	connected_players.erase(player_id)
	_update_player_list()

func _add_player_to_list(player_id: int, player_name: String):
	connected_players[player_id] = player_name

func _on_change_name_pressed():
	_change_name()

func _on_name_submitted(_text: String):
	_change_name()

func _change_name():
	var new_name = name_input.text.strip_edges()
	if new_name.is_empty():
		status_label.text = "Please enter a valid name"
		return
	
	var my_id = multiplayer.get_unique_id()
	if is_host:
		# If we're the server, call the authoritative handler directly
		Network.request_name_change(my_id, new_name)
	else:
		Network.rpc_id(1, "request_name_change", my_id, new_name)
	status_label.text = "Changing name to: " + new_name

func _on_player_list_updated(players: Dictionary):
	connected_players = players.duplicate()
	_update_player_list()

func _display_host_ip():
	if not ip_label:
		return
	
	var ip_addresses = IP.get_local_addresses()
	var host_ip = "Not Found"
	
	print("========================================")
	print("HOST IP DETECTION")
	print("All IP addresses detected: ", ip_addresses)
	
	var valid_ips = []
	
	# Collect all valid private network IPs
	for ip in ip_addresses:
		if typeof(ip) != TYPE_STRING:
			continue
		
		print("Checking: ", ip)
		
		# Skip localhost
		if ip == "127.0.0.1" or ip == "::1":
			print("  -> Skipped (localhost)")
			continue
		
		# Skip link-local
		if ip.begins_with("169.254") or ip.begins_with("fe80"):
			print("  -> Skipped (link-local)")
			continue
		
		# Skip IPv6 (contains colon)
		if ":" in ip:
			print("  -> Skipped (IPv6)")
			continue
		
		# Collect private network IPs
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			valid_ips.append(ip)
			print("  -> Added to valid IPs")
		elif ip.begins_with("172."):
			var parts = ip.split(".")
			if parts.size() >= 2:
				var second_octet = int(parts[1])
				if second_octet >= 16 and second_octet <= 31:
					valid_ips.append(ip)
					print("  -> Added to valid IPs")
	
	print("Valid IPs found: ", valid_ips)
	
	# If we have multiple IPs, prefer the one that's NOT a virtual adapter
	if valid_ips.size() > 1:
		for ip in valid_ips:
			# Skip common virtual adapter IPs
			if ip.ends_with(".137.1"):  # Windows Mobile Hotspot
				print("  ", ip, " -> Skipped (likely virtual adapter)")
				continue
			if ip.ends_with(".1.1"):  # Common virtual adapter
				print("  ", ip, " -> Skipped (likely virtual adapter)")
				continue
			# Prefer this IP
			host_ip = ip
			print("  ", ip, " -> SELECTED! (likely physical adapter)")
			break
	elif valid_ips.size() == 1:
		host_ip = valid_ips[0]
		print("  ", host_ip, " -> Only valid IP found")
	
	ip_label.text = "Share this IP: " + host_ip + " | Port: " + str(Network.DEFAULT_PORT)
	ip_label.visible = true
	
	print("Final IP shown to host: ", host_ip)
	print("========================================")

func _update_player_list():
	# Clear existing player labels
	for child in player_list_vbox.get_children():
		child.queue_free()
	
	# Add current players
	for player_id in connected_players.keys():
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = connected_players[player_id] + " (ID: " + str(player_id) + ")"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hbox.add_child(label)
		
		# Add host indicator
		if int(player_id) == 1:
			var host_label = Label.new()
			host_label.text = " [HOST]"
			host_label.modulate = Color.YELLOW
			hbox.add_child(host_label)
		
		player_list_vbox.add_child(hbox)
	
	# Update start game button state
	if is_host:
		var min_players = 2
		var max_players = Network.MAX_PLAYERS
		start_game_button.disabled = connected_players.size() < min_players
		status_label.text = "Players: " + str(connected_players.size()) + "/" + str(max_players)

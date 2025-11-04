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
	var local_ip = "Run 'ipconfig' to find IP"
	
	print("========================================")
	print("All detected IP addresses: ", ip_addresses)
	print("========================================")
	
	# First, try to get a LAN IP (most common for local network play)
	var primary_ip = _get_primary_ip()
	if primary_ip != "":
		local_ip = primary_ip
		print("✓ Selected Primary IP: ", local_ip)
	else:
		# Fallback: Find the first non-localhost, non-link-local IPv4 address
		for ip in ip_addresses:
			print("Checking IP: ", ip)
			# Skip localhost and link-local addresses
			if ip == "127.0.0.1" or ip == "::1":
				print("  -> Skipped (localhost)")
				continue
			if ip.begins_with("169.254") or ip.begins_with("fe80"):
				print("  -> Skipped (link-local)")
				continue
			# Skip IPv6 addresses (contain colons)
			if ":" in ip:
				print("  -> Skipped (IPv6)")
				continue
			# Found a valid IPv4 address
			local_ip = ip
			print("  -> Selected!")
			break
	
	ip_label.text = "Your IP: " + local_ip
	print("========================================")
	print("Final IP displayed: ", local_ip)
	print("========================================")

func _get_primary_ip() -> String:
	# Try to get the primary network interface IP
	var ip_addresses = IP.get_local_addresses()
	
	print("Searching for primary IP from: ", ip_addresses)
	
	var valid_ips = []
	
	# Collect all valid private network IPs
	for ip in ip_addresses:
		if typeof(ip) != TYPE_STRING:
			continue
		
		# Skip localhost, link-local, and IPv6
		if ip == "127.0.0.1" or ip == "::1":
			continue
		if ip.begins_with("169.254") or ip.begins_with("fe80"):
			continue
		if ":" in ip:  # Skip IPv6
			continue
		
		# Collect 192.168.x.x IPs
		if ip.begins_with("192.168."):
			valid_ips.append(ip)
			print("Found 192.168.x.x IP: ", ip)
		# Collect 10.x.x.x IPs
		elif ip.begins_with("10."):
			valid_ips.append(ip)
			print("Found 10.x.x.x IP: ", ip)
		# Collect 172.16-31.x.x IPs
		elif ip.begins_with("172."):
			var parts = ip.split(".")
			if parts.size() >= 2:
				var second_octet = int(parts[1])
				if second_octet >= 16 and second_octet <= 31:
					valid_ips.append(ip)
					print("Found 172.16-31.x.x IP: ", ip)
	
	# If we have multiple IPs, prefer the one that's NOT .137.1 (common virtual adapter)
	# Also avoid .1 addresses as they're often gateways/virtual adapters
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
			print("  ", ip, " -> Selected (likely physical adapter)")
			return ip
	
	# If we still have valid IPs, return the first one
	if valid_ips.size() > 0:
		print("Using first available IP: ", valid_ips[0])
		return valid_ips[0]
	
	# Priority 2: Fallback to any non-localhost IPv4
	for ip in ip_addresses:
		if typeof(ip) != TYPE_STRING:
			continue
		if ip == "127.0.0.1" or ip == "::1":
			continue
		if ip.begins_with("169.254") or ip.begins_with("fe80"):
			continue
		if ":" in ip:  # Skip IPv6
			continue
		print("Found fallback IPv4: ", ip)
		return ip
	
	print("No valid IP found!")
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

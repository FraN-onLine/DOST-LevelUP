extends Node

const DEFAULT_IP := "localhost"
const DEFAULT_PORT := 12345
# Editable maximum players (default 2). Exported so it can be changed in the singleton's inspector if desired.
@export var MAX_PLAYERS: int = 2

signal player_joined(peer_id)
signal player_left(peer_id)
signal connected(success, reason)
signal player_list_updated(players)
signal game_started

var peer: ENetMultiplayerPeer
var started = false
var players := {} # peer_id -> name
var player_instances := {} # peer_id -> NodePath (server-side reference)
var player_hands := {} # peer_id -> Array[int] (authoritative hands)
var ready_peers := {} # peer_id -> true when that peer has loaded the Game scene

func _ready():
	# Connect multiplayer signals to forward events
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)

func start_host(port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		emit_signal("connected", false, "create_server_failed")
		return
	multiplayer.multiplayer_peer = peer
	
	# Add host to players list
	var host_id = multiplayer.get_unique_id()
	players[host_id] = "Host"
	broadcast_player_list()
	
	print("Server started on port %d" % port)
	emit_signal("connected", true, "host_started")

func stop_host() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
		peer = null
		print("Server stopped")
		emit_signal("connected", false, "host_stopped")

func join_host(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to create client: %s" % err)
		emit_signal("connected", false, "create_client_failed")
		return
	multiplayer.multiplayer_peer = peer
	print("Attempting connection to %s:%d" % [ip, port])

func leave_host() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
		peer = null
		print("Left host / disconnected")

func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	# Enforce player cap on server
	if multiplayer.is_server():
		var current := players.size()
		if current >= MAX_PLAYERS:
			print("Max players reached (%d). Disconnecting peer %d" % [MAX_PLAYERS, id])
			# Disconnect the peer (ENet uses peer IDs)
			if peer:
				peer.disconnect_peer(id)
			return
		# Assign a default name and broadcast
		players[id] = "Player %d" % id
		broadcast_player_list()
	emit_signal("player_joined", id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	# Remove from player list on server and broadcast
	if multiplayer.is_server():
		if id in players:
			players.erase(id)
			broadcast_player_list()
	emit_signal("player_left", id)

func _on_connection_succeeded() -> void:
	print("Connection succeeded")
	emit_signal("connected", true, "connected")

func _on_connection_failed() -> void:
	print("Connection failed")
	emit_signal("connected", false, "failed")

func broadcast_player_list() -> void:
	# Send the current player dictionary to all peers
	print("Broadcasting player list: %s" % players)
	# update local copy and emit
	emit_signal("player_list_updated", players)
	# Use multiplayer RPC to update clients
	if multiplayer.get_multiplayer_peer():
		# Send to all peers (including server) via node-level RPC
		rpc("rpc_update_player_list", players)


@rpc("any_peer", "reliable")
func request_player_list() -> void:
	# Called by clients to ask the server to broadcast the current player list
	if not multiplayer.is_server():
		return
	broadcast_player_list()

# Clients call this (via rpc_id to server) to request a name change
@rpc("any_peer", "reliable")
func request_name_change(peer_id: int, new_name: String) -> void:
	if not multiplayer.is_server():
		return
	print("Server received name change for %d -> %s" % [peer_id, new_name])
	players[peer_id] = new_name
	broadcast_player_list()
	# Send an acknowledgement directly to the requesting peer so their UI can react quickly
	# rpc_id is invoked on the server's Network node to call the client-side handler
	rpc_id(peer_id, "rpc_name_change_ack", peer_id, new_name)

@rpc("any_peer", "reliable")
func rpc_update_player_list(remote_players: Dictionary) -> void:
	# Update local view of players when server broadcasts
	players = remote_players.duplicate()
	emit_signal("player_list_updated", players)
	print("[Network] Received player list update: %s" % players)


@rpc("any_peer", "reliable")
func rpc_name_change_ack(peer_id: int, new_name: String) -> void:
	# Server ack for name change - update local copy and emit signal
	print("[Network] Name change ack for %d -> %s" % [peer_id, new_name])
	players[peer_id] = new_name
	emit_signal("player_list_updated", players)


# RPC function to start the game
@rpc("any_peer", "call_local", "reliable")
func start_game():
	# Server entry point to start the game. This version deals cards and performs a
	# handshake so that the server only spawns player instances and sends hands when
	# every peer (including the server) has finished loading the Game scene.
	if not multiplayer.is_server():
		return

	print("[Network] Starting game (deal + scene change)")
	started = true
	emit_signal("game_started")

	# Deal and change scene for all players. We'll use Game.tscn in /scenes.
	deal_and_start_game("res://scenes/Game.tscn")


@rpc("any_peer", "reliable")
func rpc_change_scene(scene_path: String) -> void:
	print("rpc_change_scene called: %s" % scene_path)
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("Scene path not found: %s" % scene_path)


# --------------------
# Game / dealing helpers
# --------------------

func deal_and_start_game(game_scene_path: String = "res://scenes/Game.tscn") -> void:
	# Build a simple deck of numeric IDs and shuffle
	var deck := []
	for i in range(1, 53):
		deck.append(i)
	deck.shuffle()

	# Prepare empty hands for each connected player
	player_hands.clear()
	for peer_id in players.keys():
		player_hands[peer_id] = []

	# Deal 3 cards each
	var cards_per_player := 3
	for i in range(cards_per_player):
		for peer_id in players.keys():
			if deck.size() == 0:
				push_warning("Deck exhausted while dealing")
				break
			player_hands[peer_id].append(deck.pop_back())

	# Reset handshake state
	ready_peers.clear()

	# Ask all peers to change scene; clients will call back rpc_client_loaded when ready
	if multiplayer.get_multiplayer_peer():
		rpc("rpc_change_scene", game_scene_path)
	# Change server scene locally
	get_tree().change_scene_to_file(game_scene_path)
	# Mark server as ready immediately (server doesn't need to rpc itself)
	var server_id = multiplayer.get_unique_id()
	ready_peers[server_id] = true

	# If there are no remote peers, spawn immediately
	_check_and_spawn_after_ready()


@rpc("any_peer", "reliable")
func rpc_client_loaded() -> void:
	# This is called by clients (rpc_id to server) to announce they finished loading Game scene
	if not multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	print("[Network] rpc_client_loaded from %d" % sender)
	ready_peers[sender] = true
	# Check if all players are ready; if so, proceed to spawn and send hands
	_check_and_spawn_after_ready()


func _check_and_spawn_after_ready() -> void:
	# Only server runs the spawn logic
	if not multiplayer.is_server():
		return
	# Ensure every player in players.keys() is marked ready
	for peer_id in players.keys():
		if not ready_peers.has(peer_id):
			return # still waiting

	# All ready: spawn player nodes and distribute hands
	_server_spawn_players_and_send_hands()


func _server_spawn_players_and_send_hands() -> void:
	# Server-side: spawn Player nodes under a 'Players' container in the active scene
	var root = get_tree().get_current_scene()
	if not root:
		push_error("No current scene when spawning players")
		return
	if not root.has_node("Players"):
		push_error("Game scene must have a 'Players' node to parent player instances")
		return
	var players_container = root.get_node("Players")

	# Load the player scene if available; if missing, we won't instantiate scene objects but still send hands
	var player_scene = ResourceLoader.load("res://scenes/Player.tscn")
	player_instances.clear()

	for peer_id in players.keys():
		# Instantiate a player node if the scene exists
		if player_scene:
			var inst = player_scene.instantiate()
			inst.name = "Player_%d" % peer_id
			players_container.add_child(inst)
			inst.set_multiplayer_authority(peer_id)
			player_instances[peer_id] = inst.get_path()
		else:
			player_instances[peer_id] = ""

		# Send the private hand to the owning peer (rpc_id -> client-side handler)
		if player_hands.has(peer_id):
			rpc_id(peer_id, "rpc_receive_private_hand", player_hands[peer_id])
		else:
			rpc_id(peer_id, "rpc_receive_private_hand", [])

	# Broadcast public counts so each client can show face-down cards for opponents
	var public_counts := {}
	var cards_per_player := 3
	for peer_id in players.keys():
		public_counts[peer_id] = cards_per_player
	rpc("rpc_set_public_hand_counts", public_counts)

	# Also broadcast player names so clients can update name labels in the Game scene
	rpc("rpc_set_player_names", players)

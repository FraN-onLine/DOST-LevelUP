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


@rpc("authority", "reliable")
func request_player_list() -> void:
	# Called by clients to ask the server to broadcast the current player list
	if not multiplayer.is_server():
		return
	broadcast_player_list()

# Clients call this (via rpc_id to server) to request a name change
@rpc("authority", "reliable")
func request_name_change(peer_id: int, new_name: String) -> void:
	if not multiplayer.is_server():
		return
	print("Server received name change for %d -> %s" % [peer_id, new_name])
	players[peer_id] = new_name
	broadcast_player_list()

@rpc("any_peer", "reliable")
func rpc_update_player_list(remote_players: Dictionary) -> void:
	# Update local view of players when server broadcasts
	players = remote_players.duplicate()
	emit_signal("player_list_updated", players)


# RPC function to start the game
@rpc("any_peer", "call_local", "reliable")
func start_game():
	if not multiplayer.is_server():
		return
	
	print("Starting game for all players")
	started = true
	emit_signal("game_started")
	# Tell all peers to change scene
	if multiplayer.get_multiplayer_peer():
		rpc("rpc_change_scene", "res://scenes/CitySurgeGame.tscn")
	# Also change server scene locally
	get_tree().change_scene_to_file("res://scenes/CitySurgeGame.tscn")


@rpc("any_peer", "reliable")
func rpc_change_scene(scene_path: String) -> void:
	print("rpc_change_scene called: %s" % scene_path)
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("Scene path not found: %s" % scene_path)

# res://scripts/Network.gd
extends Node

#this is default network code, i cant even explain this
# === CONFIG ===
@export_range(1024, 65535, 1) var port: int = 55555
@export var max_clients: int = 16

var is_server: bool = false

# Multiplayer API reference (explicitly typed)
var mp: SceneMultiplayer

# === SIGNALS ===
signal connected_to_server()
signal server_started()
signal connection_failed()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

func _ready():
	# explicit type assignment fixes the inference issue
	mp = get_tree().get_multiplayer()

	# connect signals for lifecycle
	mp.peer_connected.connect(_on_peer_connected)
	mp.peer_disconnected.connect(_on_peer_disconnected)
	mp.connection_failed.connect(_on_connection_failed)
	mp.server_disconnected.connect(_on_server_disconnected)
	print("[Network] Ready - Multiplayer system initialized.")

# === HOST ===
func start_host(p_port: int = -1) -> void:
	if p_port > 0:
		port = p_port

	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_server(port, max_clients)
	if result != OK:
		push_error("[Network] Failed to create server! Code: %s" % result)
		return

	mp.multiplayer_peer = enet
	is_server = true
	emit_signal("server_started")
	print("[Network] Host started on port %d" % port)

# === CLIENT ===
func start_client(target_ip: String, p_port: int = -1) -> void:
	if p_port > 0:
		port = p_port

	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_client(target_ip, port)
	if result != OK:
		push_error("[Network] Failed to create client! Code: %s" % result)
		return

	mp.multiplayer_peer = enet
	is_server = false
	print("[Network] Connecting to %s:%d" % [target_ip, port])

# === STOP ===
func stop_network() -> void:
	if mp and mp.has_multiplayer_peer():
		mp.multiplayer_peer = null
		print("[Network] Connection closed.")
	is_server = false

# === SIGNAL HANDLERS ===
func _on_peer_connected(id: int) -> void:
	emit_signal("peer_connected", id)
	print("[Network] Peer connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	emit_signal("peer_disconnected", id)
	print("[Network] Peer disconnected: ", id)

func _on_connection_failed() -> void:
	emit_signal("connection_failed")
	print("[Network] Connection failed!")

func _on_server_disconnected() -> void:
	print("[Network] Disconnected from server.")

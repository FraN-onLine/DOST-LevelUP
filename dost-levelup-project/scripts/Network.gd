extends Node

const IP_ADDRESS := "localhost"
const PORT := 12345
const MAX_PLAYERS := 4
var peer: ENetMultiplayerPeer

func start_server():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PORT, MAX_PLAYERS)
	if result != OK:
		push_error("Failed to create server: %s" % result)
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on %s:%d" % [IP_ADDRESS, PORT])

func start_client():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(IP_ADDRESS, PORT)
	if result != OK:
		push_error("Failed to connect to server: %s" % result)
		return
	multiplayer.multiplayer_peer = peer
	print("Connected to server at %s:%d" % [IP_ADDRESS, PORT])

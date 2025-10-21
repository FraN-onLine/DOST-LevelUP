extends Control

# Game.gd - small helper to notify the Network singleton when the Game scene has loaded
# and to provide local hookup points for UI nodes that display the local/opponent card holders.

@onready var player_cards = $PlayerCards
@onready var opponent_cards = $OpponentCards

func _ready():
	# Inform the authoritative server that this client finished loading the Game scene.
	# Server will collect these signals and, when everyone is ready, spawn players and send hands.
	if Network and Network.multiplayer:
		# Use rpc_id to call the server-side rpc_client_loaded
		Network.rpc_id(1, "rpc_client_loaded")

	# Optionally, initialize UI placeholders
	_clear_card_holders()

func _clear_card_holders():
	# If card holder scenes have children, clear them so the server's RPCs populate them
	if player_cards and player_cards.get_child_count() > 0:
		for c in player_cards.get_children():
			c.queue_free()
	if opponent_cards and opponent_cards.get_child_count() > 0:
		for c in opponent_cards.get_children():
			c.queue_free()

# These client-side RPCs are forwarded by the Network server to set public counts and
# the client's private hand. The server calls rpc_id(peer, "rpc_receive_private_hand", hand)
# which runs on the owning peer only.

# Runs on the owning client only
@rpc("any_peer", "reliable")
func rpc_receive_private_hand(hand: Array):
	# The server will send the array of card ids to the owning client
	print("[Game] Received private hand: %s" % hand)
	# Populate player_cards UI (simple labels) with actual values
	_populate_card_holder(player_cards, hand, true)

# Runs on all clients; provides how many cards each player has (public info)
@rpc("any_peer", "reliable")
func rpc_set_public_hand_counts(public_counts: Dictionary):
	# Use public_counts to populate opponent_cards with X placeholders for remote players
	print("[Game] Public counts: %s" % public_counts)
	# For a simple 2-player layout assume one opponent with peer id != local
	var my_id = multiplayer.get_unique_id()
	for peer_id in public_counts.keys():
		if peer_id == my_id:
			# our own UI is handled by rpc_receive_private_hand
			continue
		var count = public_counts[peer_id]
		_populate_card_holder(opponent_cards, Array(), false, count)

func _populate_card_holder(container: Node, hand: Array, face_up: bool, count: int = -1):
	# Clears and fills `container` with Labels for each card.
	for c in container.get_children():
		c.queue_free()

	var cards_to_create = 0
	if count >= 0:
		cards_to_create = count
	else:
		cards_to_create = hand.size()

	for i in range(cards_to_create):
		var lbl = Label.new()
		if face_up and i < hand.size():
			lbl.text = str(hand[i])
		else:
			lbl.text = "X"
		container.add_child(lbl)


@rpc("any_peer", "reliable")
func rpc_set_player_names(names: Dictionary):
	# names is a dictionary mapping peer_id -> display name
	var my_id = multiplayer.get_unique_id()
	# Find the first peer_id that is not the current peer (opponent)
	var opponent_id = -1
	for pid in names.keys():
		if pid != my_id:
			opponent_id = pid
			break

	# Set local UI labels (PlayerName on left, OpponentName on right)
	if names.has(my_id):
		if has_node("PlayerName"):
			$PlayerName.text = str(names[my_id])
	if opponent_id != -1 and names.has(opponent_id):
		if has_node("OpponentName"):
			$OpponentName.text = str(names[opponent_id])

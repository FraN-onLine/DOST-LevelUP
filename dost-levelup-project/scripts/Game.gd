extends Control

# Game.gd - small helper to notify the Network singleton when the Game scene has loaded
# and to provide local hookup points for UI nodes that display the local/opponent card holders.

@onready var player_cards = $PlayerCards
@onready var opponent_cards = $OpponentCards

func _ready():
	# Inform the authoritative server that this client finished loading the Game scene.
	# Server will collect these signals and, when everyone is ready, spawn players and send hands.
	# If we're running as the server (host), call the handler directly. Clients should rpc_id the server.
	if Network and Network.multiplayer:
		# Use helper to call locally if we're server, or rpc_id the server if client.
		Network.call_or_rpc_id(1, "rpc_client_loaded")

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
	# For each id we will try to load a Card resource (res://cards/card_<id>.tres)
	# and instantiate a card slot for it so the card graphic appears.
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
	# Clears and fills `container` with Card Slot instances (res://UI/card_slot.tscn)
	for c in container.get_children():
		c.queue_free()

	var cards_to_create = 0
	if count >= 0:
		cards_to_create = count
	else:
		cards_to_create = hand.size()

	var card_slot_scene := preload("res://UI/card_slot.tscn")
	for i in range(cards_to_create):
		var card_slot_inst = card_slot_scene.instantiate()
		# If face_up and we have an id for this slot, try to load the Card resource
		if face_up and i < hand.size():
			var cid = hand[i]
			var res_path = "res://cards/card_%d.tres" % cid
			if ResourceLoader.exists(res_path):
				var card_res = ResourceLoader.load(res_path)
				if card_res and card_res is Resource and card_res.texture:
					card_slot_inst.get_node("CenterContainer/Panel/itemDisplay").texture = card_res.texture
				else:
					# fallback: show numeric id as label inside the slot panel
					var lbl = Label.new()
					lbl.text = str(cid)
					card_slot_inst.get_node("CenterContainer/Panel").add_child(lbl)
			else:
				var lbl2 = Label.new()
				lbl2.text = str(cid)
				card_slot_inst.get_node("CenterContainer/Panel").add_child(lbl2)
		else:
			# face-down: hide the item display texture (or set a placeholder)
			card_slot_inst.get_node("CenterContainer/Panel/itemDisplay").visible = false

		container.add_child(card_slot_inst)


@rpc("any_peer", "reliable")
func rpc_set_player_names(names: Dictionary):
	# names is a dictionary mapping peer_id -> display name
	# RPC serialization can convert integer keys to strings, so coerce keys to int
	var my_id = multiplayer.get_unique_id()
	var my_name = null
	var opp_name = null
	for raw_key in names.keys():
		var pid = int(raw_key)
		var pname = names[raw_key]
		if pid == my_id:
			my_name = pname
		else:
			# take the first other peer as opponent (works for 2-player layout)
			if opp_name == null:
				opp_name = pname

	# Set local UI labels (PlayerName on left, OpponentName on right)
	if my_name != null and has_node("PlayerName"):
		$PlayerName.text = str(my_name)
	if opp_name != null and has_node("OpponentName"):
		$OpponentName.text = str(opp_name)

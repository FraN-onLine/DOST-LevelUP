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
	# Do not free slot nodes. Instead deactivate the item display inside each
	# existing slot so the layout remains intact and we avoid creating new slots.
	if player_cards and player_cards.get_child_count() > 0:
		for holder in player_cards.get_children():
			var layout = holder
			if holder.has_node("GridContainer"):
				layout = holder.get_node("GridContainer")
			for slot_node in layout.get_children():
				if slot_node.has_node("CenterContainer/Panel/itemDisplay"):
					slot_node.get_node("CenterContainer/Panel/itemDisplay").visible = false
				# remove any dynamic labels left from previous fills
				var panel = slot_node.get_node("CenterContainer/Panel")
				for child in panel.get_children():
					if child.name != "itemDisplay":
						child.queue_free()
	if opponent_cards and opponent_cards.get_child_count() > 0:
		for holder in opponent_cards.get_children():
			var layout2 = holder
			if holder.has_node("GridContainer"):
				layout2 = holder.get_node("GridContainer")
			for slot2_node in layout2.get_children():
				if slot2_node.has_node("CenterContainer/Panel/itemDisplay"):
					slot2_node.get_node("CenterContainer/Panel/itemDisplay").visible = false
				var panel2 = slot2_node.get_node("CenterContainer/Panel")
				for child2 in panel2.get_children():
					if child2.name != "itemDisplay":
						child2.queue_free()

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
	# Find a layout container inside the provided holder. Prefer a child GridContainer
	# (card_holder.tscn provides one named "GridContainer") so cards are spaced evenly.
	var layout_node: Node = container
	if container.has_node("GridContainer"):
		layout_node = container.get_node("GridContainer")

	# Do NOT clear or free children. Reuse existing card_slot nodes already present in
	# the `card_holder` GridContainer. This prevents creating duplicate nodes.

	# Determine how many slots we should show
	var cards_to_create = 0
	if count >= 0:
		cards_to_create = count
	else:
		cards_to_create = hand.size()

	# If the layout is a GridContainer, set the number of columns to space cards evenly
	if typeof(layout_node) == TYPE_OBJECT and layout_node is GridContainer:
		layout_node.columns = cards_to_create

	# Reuse existing slot nodes; do NOT instantiate new slots. If there are fewer
	# slots than needed, warn and skip the extra slots.
	var existing = layout_node.get_child_count()
	if existing == 0:
		push_warning("Card holder has no child slots; expected at least one slot.")

	for i in range(cards_to_create):
		if i >= existing:
			push_warning("Not enough slots in holder; expected %d but found %d" % [cards_to_create, existing])
			continue

		var card_slot_inst: Node = layout_node.get_child(i)
		# clear previous dynamic children inside the Panel (except itemDisplay)
		var panel = card_slot_inst.get_node("CenterContainer/Panel")
		for child in panel.get_children():
			if child.name != "itemDisplay":
				child.queue_free()

		# set slot index so clicks can be identified
		card_slot_inst.slot_index = i

		# connect click signal once (avoid duplicate connections)
		var click_callable = Callable(self, "_on_card_clicked")
		if not card_slot_inst.is_connected("slot_clicked", click_callable):
			card_slot_inst.connect("slot_clicked", click_callable)

		# Fill the slot: if face_up and we have an id for this slot, try to load the Card resource
		if face_up and i < hand.size():
			var cid = hand[i]
			var res_path = "res://cards/card_%d.tres" % cid
			var itemDisplay = card_slot_inst.get_node("CenterContainer/Panel/itemDisplay")
			if ResourceLoader.exists(res_path):
				var card_res = ResourceLoader.load(res_path)
				if card_res and card_res is Resource and card_res.texture:
					itemDisplay.texture = card_res.texture
					itemDisplay.visible = true
				else:
					var lbl = Label.new()
					lbl.text = str(cid)
					panel.add_child(lbl)
					itemDisplay.visible = false
			else:
				var lbl2 = Label.new()
				lbl2.text = str(cid)
				panel.add_child(lbl2)
				itemDisplay.visible = false
		else:
			# face-down: hide the item display texture (or set a placeholder)
			card_slot_inst.get_node("CenterContainer/Panel/itemDisplay").visible = false


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


func _on_card_clicked(slot_index: int) -> void:
	# Handle a local click on a card slot. Slot indices are 0-based from the left.
	print("[Game] Card slot clicked:", slot_index)

	# TODO: send selection to server or handle local interactions. Keeping this local
	# avoids introducing new server RPCs in this change.


@rpc("any_peer", "reliable")
func rpc_update_energies(energies: Dictionary) -> void:
	# Update UI labels for player and opponent energy whenever the server broadcasts
	var my_id = multiplayer.get_unique_id()
	var my_energy = null
	var opp_energy = null
	for raw_key in energies.keys():
		var pid = int(raw_key)
		var val = energies[raw_key]
		if pid == my_id:
			my_energy = val
		else:
			if opp_energy == null:
				opp_energy = val

	if my_energy != null and has_node("PlayerEnergy"):
		$PlayerEnergy.text = str(my_energy)
	if opp_energy != null and has_node("OpponentEnergy"):
		$OpponentEnergy.text = str(opp_energy)

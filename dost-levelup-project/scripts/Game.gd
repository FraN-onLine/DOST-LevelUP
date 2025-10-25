extends Control

# Game.gd - small helper to notify the Network singleton when the Game scene has loaded
# and to provide local hookup points for UI nodes that display the local/opponent card holders.

@onready var player_cards = $PlayerCards
@onready var opponent_cards = $OpponentCards
var local_hand: Hand = null
var card_pool_meta := {}
var revealed_cards := {} # peer_id -> { slot_index: card_id }

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
	# Build a Hand resource instance from the playerhand template and the received ids
	var template = ResourceLoader.load("res://cards/playerhand.tres")
	if template:
		# deep duplicate so we can modify slots safely
		local_hand = template.duplicate(true)
	else:
		# fallback: create minimal Hand instance
		local_hand = Hand.new()

	# Fill hand resource slots with Card resources where available
	for i in range(local_hand.slots.size()):
		if i < hand.size():
			var cid = hand[i]
			var res_path = "res://cards/card_%d.tres" % cid
			if ResourceLoader.exists(res_path):
				var card_res = ResourceLoader.load(res_path)
				local_hand.slots[i].item = card_res
			else:
				local_hand.slots[i].item = null
		else:
			local_hand.slots[i].item = null

	# Populate UI using the id array (keeps existing behavior) and keep local_hand for monitoring
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
	# Find the layout GridContainer inside the holder
	var layout_node: Node = container
	if container.has_node("GridContainer"):
		layout_node = container.get_node("GridContainer")

	# Determine how many slots to iterate: always prefer explicit count, otherwise 3
	var cards_to_create = 3
	if count >= 0:
		cards_to_create = count

	var existing = layout_node.get_child_count()
	if existing == 0:
		push_warning("Card holder has no child slots; expected at least one slot.")

	# Iterate over expected slots and update visuals based on local_hand (for player)
	for i in range(cards_to_create):
		if i >= existing:
			push_warning("Not enough slots in holder; expected %d but found %d" % [cards_to_create, existing])
			continue

		var slot_node: Node = layout_node.get_child(i)
		var panel = slot_node.get_node("CenterContainer/Panel")
		# remove dynamic labels
		for child in panel.get_children():
			if child.name != "itemDisplay":
				child.queue_free()

		# Set slot index if present
		slot_node.slot_index = i

		# Connect click signal once
		var click_callable = Callable(self, "_on_card_clicked")
		if not slot_node.is_connected("slot_clicked", click_callable):
			slot_node.connect("slot_clicked", click_callable)

		# For player holder: show item if local_hand has item in this slot
		if container == player_cards and local_hand != null:
			var s = local_hand.slots[i]
			var itemDisplay = slot_node.get_node("CenterContainer/Panel/itemDisplay")
			# Prefer explicit face_up/face_down textures if defined on the Card resource
			var tex: Texture2D = null
			if s.item != null:
				if s.item and face_up and s.item.texture_face_up != null:
					tex = s.item.texture_face_up
				elif s.item and not face_up and s.item.texture_face_down != null:
					tex = s.item.texture_face_down
				

			if tex != null:
				itemDisplay.texture = tex
				itemDisplay.visible = true
			else:
				itemDisplay.visible = false
		else:
			# Opponent or face-down: show a card-back texture if available
			var itemDisplay2 = slot_node.get_node("CenterContainer/Panel/itemDisplay")
			var back_tex: Texture2D = null
			# Try to use card_pool_meta first
			if card_pool_meta.size() > 0:
				var first_key = card_pool_meta.keys()[0]
				var back_path = card_pool_meta[first_key]["path"]
				if ResourceLoader.exists(back_path):
					var back_res = ResourceLoader.load(back_path)
					if back_res and back_res.texture_face_down != null:
						back_tex = back_res.texture_face_down
					elif back_res and back_res.texture_face_up != null:
						back_tex = back_res.texture_face_up
			# Fallback to card_1
			# Prefer explicit Network.card_back if set
			if back_tex == null and Network and Network.card_back != null:
				back_tex = Network.card_back
			# Fallback to card_1 resource
			if back_tex == null and ResourceLoader.exists("res://cards/card_1.tres"):
				var fb = ResourceLoader.load("res://cards/card_1.tres")
				if fb and fb.texture_face_down != null:
					back_tex = fb.texture_face_down
				elif fb and fb.texture_face_up != null:
					back_tex = fb.texture_face_up
			# If this opponent slot has been revealed, show the revealed card face-up
			var my_id = multiplayer.get_unique_id()
			# Assume a single-opponent layout; find the peer id of the opponent if available
			var revealed_card_id = null
			for raw_key in revealed_cards.keys():
				var pid = int(raw_key)
				if pid != my_id:
					var map = revealed_cards[raw_key]
					if map.has(i):
						revealed_card_id = map[i]
						break
			if revealed_card_id != null:
				var res_path = "res://cards/card_%d.tres" % int(revealed_card_id)
				if ResourceLoader.exists(res_path):
					var card_res = ResourceLoader.load(res_path)
					if card_res and card_res.texture_face_up != null:
						itemDisplay2.texture = card_res.texture_face_up
						itemDisplay2.visible = true
						continue
			# No reveal for this slot: show back texture if available
			if back_tex != null:
				itemDisplay2.texture = back_tex
				itemDisplay2.visible = true
			else:
				itemDisplay2.visible = false


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


@rpc("any_peer", "reliable")
func rpc_reveal_public_card(peer_id: int, slot_index: int, card_id: int) -> void:
	# Server-authoritative broadcast that a specific peer's slot was revealed and
	# which card id it contained. Store locally and update opponent UI.
	var key = str(peer_id)
	if not revealed_cards.has(key):
		revealed_cards[key] = {}
	revealed_cards[key][slot_index] = int(card_id)
	# If this reveal applies to an opponent UI, update that slot display now
	var my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		# Owner already knows their cards; nothing to do
		return
	# Find the opponent holder and set the texture for the given slot
	if opponent_cards and opponent_cards.get_child_count() > 0:
		var holder = opponent_cards.get_child(0)
		var layout = holder
		if holder.has_node("GridContainer"):
			layout = holder.get_node("GridContainer")
		if slot_index < layout.get_child_count():
			var slot_node = layout.get_child(slot_index)
			var itemDisplay = slot_node.get_node("CenterContainer/Panel/itemDisplay")
			var res_path = "res://cards/card_%d.tres" % int(card_id)
			if ResourceLoader.exists(res_path):
				var card_res = ResourceLoader.load(res_path)
				if card_res and card_res.texture_face_up != null:
					itemDisplay.texture = card_res.texture_face_up
					itemDisplay.visible = true
				elif card_res and card_res.texture_face_down != null:
					itemDisplay.texture = card_res.texture_face_down
					itemDisplay.visible = true
			else:
				push_warning("rpc_reveal_public_card: resource not found %s" % res_path)


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


func rpc_set_card_pool(pool_meta: Dictionary) -> void:
	# Store the card pool metadata for UI/debug monitoring (id -> name/path/frequency)
	card_pool_meta = pool_meta.duplicate()
	print("[Game] Received card pool metadata: %s" % card_pool_meta)

extends Control

# Game.gd - manages card display, selection, and building placement
# Uses CardSlot functions properly for card display and selection

@onready var player_cards = $PlayerCards
@onready var opponent_cards = $OpponentCards
var local_hand: Hand = null
var card_pool_meta := {}
var revealed_cards := {} # peer_id -> { slot_index: card_id }
var selected_card_id = null
var selected_card_slot_index = null
@export var card_reveal_duration := 1.0 # Duration in seconds to show revealed cards

func _ready():
	# Inform the authoritative server that this client finished loading the Game scene.
	# Server will collect these signals and, when everyone is ready, spawn players and send hands.
	# If we're running as the server (host), call the handler directly. Clients should rpc_id the server.
	if Network and Network.multiplayer:
		Network.call_or_rpc_id(1, "rpc_client_loaded")

	# Optionally, initialize UI placeholders
	_clear_card_holders()
	# Connect plot slots so player can tap to place buildings
	_connect_plot_slots()

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

func _highlight_playable_cards(current_energy: int):
	if not player_cards or local_hand == null:
		return
	var layout = player_cards.get_child(0)
	if layout.has_node("GridContainer"):
		layout = layout.get_node("GridContainer")
	for i in range(local_hand.slots.size()):
		var card_slot = local_hand.slots[i]
		var node = layout.get_child(i)
		# call UI method on slot node to set playable/dim state
		if card_slot.item != null:
			var cost = card_slot.item.cost if card_slot.item.has_method("cost") else 1
			node.call_deferred("set_playable", current_energy >= cost)
		else:
			node.call_deferred("set_playable", false)
		# reflect selection state
		if selected_card_slot_index != null and selected_card_slot_index == i:
			node.call_deferred("set_selected", true)
		else:
			node.call_deferred("set_selected", false)

func _on_card_clicked(slot_index: int) -> void:
	print("[Game] Card slot clicked:", slot_index)
	
	# First determine if this is a player or opponent card based on which container was clicked
	var in_player_cards := false
	
	# Check if clicked slot is in player_cards
	if player_cards and player_cards.get_child_count() > 0:
		var layout = player_cards.get_child(0)
		if layout.has_node("GridContainer"):
			layout = layout.get_node("GridContainer")
		if slot_index < layout.get_child_count():
			in_player_cards = true
	
	# If it's a player card, handle selection and validation
	if in_player_cards and local_hand != null and slot_index >= 0 and slot_index < local_hand.slots.size():
		var card_slot = local_hand.slots[slot_index]
		if card_slot.item != null:
			# Select the card if player has enough energy
			var card_cost = card_slot.item.cost if card_slot.item.has_method("cost") else 1
			var my_id = multiplayer.get_unique_id()
			var current_energy = Network.player_energy.get(my_id, 0)
			if current_energy >= card_cost:
				# Deselect previous selection
				if selected_card_slot_index != null and selected_card_slot_index >= 0:
					# clear previous visual
					var prev_layout = player_cards.get_child(0)
					if prev_layout.has_node("GridContainer"):
						prev_layout = prev_layout.get_node("GridContainer")
					if selected_card_slot_index < prev_layout.get_child_count():
						var prev_node = prev_layout.get_child(selected_card_slot_index)
						prev_node.call_deferred("set_selected", false)
				# set new selection
				selected_card_id = card_slot.item.id
				selected_card_slot_index = slot_index
				var layout = player_cards.get_child(0)
				if layout.has_node("GridContainer"):
					layout = layout.get_node("GridContainer")
				if slot_index < layout.get_child_count():
					var node = layout.get_child(slot_index)
					node.call_deferred("set_selected", true)
				print("[Game] Selected card id:", selected_card_id)
			else:
				print("[Game] Not enough energy to select card (cost: %d, current: %d)" % [card_cost, current_energy])
	# If it's an opponent card, request reveal
	elif not in_player_cards:
		var opp_id = _get_opponent_peer_id()
		if opp_id > 0:
			Network.request_reveal_peer_card(opp_id, slot_index)

func _replace_card(slot_index: int) -> void:
	if not Network or not Network.available_card_ids or Network.available_card_ids.is_empty():
		return
		
	# Pick a random card from available pool
	var available = Network.available_card_ids
	var new_id = available[randi() % available.size()]
	
	# Load the card resource
	var res_path = "res://cards/card_%d.tres" % new_id
	if ResourceLoader.exists(res_path):
		var card_res = ResourceLoader.load(res_path)
		if local_hand and slot_index >= 0 and slot_index < local_hand.slots.size():
			local_hand.slots[slot_index].item = card_res
			# Update UI
			_populate_card_holder(player_cards, [], true)

# Connect player plot buttons so taps can place buildings
func _connect_plot_slots() -> void:
	if not has_node("PlayerPlot"):
		return
	var player_plot = $PlayerPlot
	var container = player_plot
	if player_plot.has_node("GridContainer"):
		container = player_plot.get_node("GridContainer")
	for i in range(container.get_child_count()):
		var btn = container.get_child(i)
		if btn:
			# Connect with index bound as argument
			if not btn.is_connected("pressed", _on_plot_pressed.bind(i)):
				btn.connect("pressed", _on_plot_pressed.bind(i))

# Handler when a plot is pressed by the local player
func _on_plot_pressed(idx := -1) -> void:
	var plot_index := idx
	if plot_index < 0:
		print("[Game] Invalid plot index")
		return
	if selected_card_slot_index == null or selected_card_slot_index < 0:
		print("[Game] No card selected to place")
		return
	# Sanity checks
	if local_hand == null:
		print("[Game] No local hand")
		return
	if selected_card_slot_index >= local_hand.slots.size():
		print("[Game] Selected slot index out of range")
		return
	var card_slot = local_hand.slots[selected_card_slot_index]
	var my_id = multiplayer.get_unique_id()
	var card_id = card_slot.item.id
	var card_cost = card_slot.item.cost if card_slot.item.has_method("cost") else 1
	var current_energy = Network.player_energy.get(my_id, 0)
	if current_energy < card_cost:
		print("[Game] Not enough energy to place building")
		return
	# Request server to place building (server will validate and broadcast)
	if Network:
		Network.request_place_building(my_id, plot_index, card_id)
	# Locally remove the card and schedule replacement
	local_hand.remove_from_slot(selected_card_slot_index)
	# clear selection visuals
	var layout = player_cards.get_child(0)
	if layout.has_node("GridContainer"):
		layout = layout.get_node("GridContainer")
	if selected_card_slot_index < layout.get_child_count():
		var node = layout.get_child(selected_card_slot_index)
		node.call_deferred("set_selected", false)
	# schedule replacement
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_replace_card.bind(selected_card_slot_index))
	_populate_card_holder(player_cards, [], true)
	selected_card_slot_index = -1
	selected_card_id = null

func _get_opponent_peer_id() -> int:
	if not Network or not Network.players:
		return -1
	var my_id = multiplayer.get_unique_id()
	# In 2-player game, find first id that isn't ours
	for peer_id in Network.players.keys():
		if peer_id != my_id:
			return peer_id
	return -1

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

func _populate_card_holder(container: Node, _hand: Array, face_up: bool, count: int = -1):
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
	# Server-authoritative broadcast that a specific peer's slot was revealed
	var key = str(peer_id)
	if not revealed_cards.has(key):
		revealed_cards[key] = {}
	revealed_cards[key][slot_index] = int(card_id)
	
	# Skip if it's our own card - we already see it
	var my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		return
		
	# Update opponent UI to show revealed card
	_show_opponent_card(peer_id, slot_index, card_id)
	
	# Start timer to hide the card after reveal_duration
	var timer = get_tree().create_timer(card_reveal_duration)
	timer.timeout.connect(func(): _hide_opponent_card(peer_id, slot_index))

func _show_opponent_card(_peer_id: int, slot_index: int, card_id: int) -> void:
	if not opponent_cards or opponent_cards.get_child_count() == 0:
		return
		
	var holder = opponent_cards.get_child(0)
	var layout = holder
	if holder.has_node("GridContainer"):
		layout = holder.get_node("GridContainer")
		
	if slot_index >= layout.get_child_count():
		return
		
	var slot_node = layout.get_child(slot_index)
	var item_display = slot_node.get_node("CenterContainer/Panel/itemDisplay")
	
	var res_path = "res://cards/card_%d.tres" % int(card_id)
	if not ResourceLoader.exists(res_path):
		push_warning("rpc_reveal_public_card: resource not found %s" % res_path)
		return
		
	var card_res = ResourceLoader.load(res_path)
	if card_res.texture_face_up != null:
		item_display.texture = card_res.texture_face_up
		item_display.visible = true
	elif card_res.texture_face_down != null:
		item_display.texture = card_res.texture_face_down
		item_display.visible = true

func _hide_opponent_card(peer_id: int, slot_index: int) -> void:
	# Remove from revealed cards
	var key = str(peer_id)
	if revealed_cards.has(key):
		revealed_cards[key].erase(slot_index)
	
	# Update opponent UI to show card back
	if not opponent_cards or opponent_cards.get_child_count() == 0:
		return
		
	var holder = opponent_cards.get_child(0)
	var layout = holder
	if holder.has_node("GridContainer"):
		layout = holder.get_node("GridContainer")
		
	if slot_index >= layout.get_child_count():
		return
		
	# Show card back if one is available
	var slot_node = layout.get_child(slot_index)
	var item_display = slot_node.get_node("CenterContainer/Panel/itemDisplay")
	
	var back_tex: Texture2D = null
	if Network and Network.card_back != null:
		back_tex = Network.card_back
	elif ResourceLoader.exists("res://cards/card_1.tres"):
		var fb = ResourceLoader.load("res://cards/card_1.tres")
		if fb.texture_face_down != null:
			back_tex = fb.texture_face_down
		elif fb.texture_face_up != null:
			back_tex = fb.texture_face_up
			
	if back_tex != null:
		item_display.texture = back_tex
		item_display.visible = true
	else:
		item_display.visible = false



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
		$PlayerEnergy.text = "Energy: " + str(my_energy)
	if opp_energy != null and has_node("OpponentEnergy"):
		$OpponentEnergy.text = "Energy: " + str(opp_energy)


func rpc_set_card_pool(pool_meta: Dictionary) -> void:
	# Store the card pool metadata for UI/debug monitoring (id -> name/path/frequency)
	card_pool_meta = pool_meta.duplicate()
	print("[Game] Received card pool metadata: %s" % card_pool_meta)

func get_selected_card_id():
	return selected_card_id


@rpc("any_peer", "reliable")
func rpc_place_building(owner_peer_id: int, plot_index: int, card_id: int) -> void:
	# Server broadcast: update the UI for the player by placing the appropriate building
	var root = get_tree().get_current_scene()
	if not root:
		return
	if not root.has_node("Players"):
		# no player nodes present; nothing to attach to
		return
	var players_node = root.get_node("Players")
	var pname = "Player_%d" % owner_peer_id
	if not players_node.has_node(pname):
		push_warning("rpc_place_building: player node %s not found" % pname)
		return
	var player_node = players_node.get_node(pname)
	# Try to find a plot container under the player node: common names are PlayerPlot, Plots, PlotContainer
	var plot_container: Node = null
	for candidate in ["PlayerPlot", "Plots", "PlotContainer"]:
		if player_node.has_node(candidate):
			var c = player_node.get_node(candidate)
			if c and c.has_node("GridContainer"):
				plot_container = c.get_node("GridContainer")
				break
			elif c and c is GridContainer:
				plot_container = c
				break
	# as fallback check direct GridContainer child
	if plot_container == null:
		for child in player_node.get_children():
			if child is GridContainer:
				plot_container = child
				break
	if plot_container == null:
		# can't place visually without a plot grid; as fallback, log and return
		push_warning("rpc_place_building: no plot grid found under player %s" % pname)
		return
	# find the plot node by name Plot_<index> or by child index
	var plot_node: Node = null
	var plot_name = "Plot_%d" % plot_index
	if plot_container.has_node(plot_name):
		plot_node = plot_container.get_node(plot_name)
	elif plot_index < plot_container.get_child_count():
		plot_node = plot_container.get_child(plot_index)
	if plot_node == null:
		push_warning("rpc_place_building: plot node not found for index %d" % plot_index)
		return
	# If the plot node has a TextureRect child named Building, set its texture from the building scene
	if plot_node.has_node("Building"):
		var texr = plot_node.get_node("Building")
		# For card id 1, use buildings/water_pump.tscn: extract first frame texture
		if card_id == 1 and ResourceLoader.exists("res://buildings/water_pump.tscn"):
			var b_scene = ResourceLoader.load("res://buildings/water_pump.tscn")
			if b_scene and b_scene is PackedScene:
				var inst = b_scene.instantiate()
				# try to read AnimatedSprite2D sprite_frames first frame
				if inst.has_method("get_sprite_frames") or inst is AnimatedSprite2D:
					var sprite = inst
					var frames = sprite.sprite_frames
					if frames and frames.get_animation_count() > 0:
						var anim = frames.get_animation_names()[0]
						if frames.get_frame_count(anim) > 0:
							var ftex = frames.get_frame(anim, 0)
							if ftex:
								texr.texture = ftex
								texr.visible = true
								return
		# fallback: clear
		texr.visible = false
	else:
		push_warning("rpc_place_building: plot node has no Building child to set texture")

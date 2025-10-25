extends Node

# Lightweight Player node used by the server to set authority and by clients to display cards.
# This node expects a child Control node named 'Cards' (HBox or VBox) to hold card Labels.

@onready var cards = $Cards
var hand = [Card] # The player's current hand of cards

func _ready():
	# Show placeholder until the Network rpc populates the cards
	_clear_cards()
	# Optionally instance a PlayerPlot scene if present so players have a plot grid by default
	if ResourceLoader.exists("res://scenes/player_plot.tscn") and not has_node("PlayerPlot"):
		var ps = ResourceLoader.load("res://scenes/player_plot.tscn")
		if ps and ps is PackedScene:
			var inst = ps.instantiate()
			inst.name = "PlayerPlot"
			add_child(inst)
			# Connect plot button signals to request placement when pressed (only for the owner)
			var grid: Node = null
			if inst.has_node("GridContainer"):
				grid = inst.get_node("GridContainer")
			elif inst is GridContainer:
				grid = inst
			if grid:
				for i in range(grid.get_child_count()):
					var p = grid.get_child(i)
					if p and p.has_method("connect"):
						p.connect("pressed", Callable(self, "_on_plot_pressed"), i)

func _on_plot_pressed(index: int) -> void:
	# Only allow owner to request placement
	var owner = get_multiplayer_authority()
	var my_id = multiplayer.get_unique_id()
	if owner != my_id:
		return
	# Ask the Game scene what card is selected and request placement
	var gs = get_tree().get_current_scene()
	if gs and gs.has_method("get_selected_card_id"):
		var cid = gs.get_selected_card_id()
		if cid != null:
			rpc_id(1, "request_place_building", owner, index, int(cid))

func _clear_cards():
	for c in cards.get_children():
		c.queue_free()

func show_hand(hand: Array, face_up: bool):
	_clear_cards()
	for i in range(hand.size()):
		var lbl = Label.new()
		lbl.text = str(hand[i]) if face_up else "X"
		cards.add_child(lbl)

# Receiving the private hand from the server (runs on the owning client)
@rpc("any_peer", "reliable")
func rpc_receive_private_hand(hand: Array):
	print("[Player] rpc_receive_private_hand: %s" % hand)
	show_hand(hand, true)

# Receiving the public counts (runs on all clients) — for non-owning clients we show X placeholders
@rpc("any_peer", "reliable")
func rpc_set_public_hand_counts(public_counts: Dictionary):
	var my_id = multiplayer.get_unique_id()
	var owner_id = get_multiplayer_authority()
	if owner_id == my_id:
		# our own player will be populated by rpc_receive_private_hand
		return
	var count = public_counts.get(owner_id, 0)
	_clear_cards()
	for i in range(count):
		var lbl = Label.new()
		lbl.text = "X"
		cards.add_child(lbl)

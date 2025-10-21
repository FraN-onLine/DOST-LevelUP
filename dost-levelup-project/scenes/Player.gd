extends Node

# Lightweight Player node used by the server to set authority and by clients to display cards.
# This node expects a child Control node named 'Cards' (HBox or VBox) to hold card Labels.

@onready var cards = $Cards

func _ready():
	# Show placeholder until the Network rpc populates the cards
	_clear_cards()

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

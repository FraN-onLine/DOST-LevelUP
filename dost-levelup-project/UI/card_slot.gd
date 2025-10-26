extends Panel

@onready var itemDisplay = $CenterContainer/Panel/itemDisplay
var name_tween: Tween = null
var _orig_item_pos: Vector2
@onready var cost_label = $Cost

signal slot_clicked(slot_index)

@export var slot_index: int = -1

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	# store the original position of the inner item display so we can animate it
	_orig_item_pos = itemDisplay.position
	# Connect mouse enter/exit to create hover animation
	if has_signal("mouse_entered"):
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	if has_signal("mouse_exited"):
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	# ensure cost label hidden by default
	if cost_label:
		cost_label.visible = false

func update(invslot: slot):
	if !invslot.item:
		itemDisplay.visible = false
	else:
		itemDisplay.visible = true
		# Prefer explicit face_up texture if available
		if invslot.item.has_method("texture_face_up") or invslot.item.texture_face_up != null:
			itemDisplay.texture = invslot.item.texture_face_up if invslot.item.texture_face_up != null else invslot.item.texture
		else:
			itemDisplay.texture = invslot.item.texture
		# Count is no longer tracked on slots — hide count label
		if $CountLabel:
			$CountLabel.visible = false
		# update cost label text (hidden until hover)
		var cost = 1
		if invslot.item and invslot.item.has_property("cost"):
			cost = int(invslot.item.cost)
		if cost_label:
			cost_label.text = str(cost)
			cost_label.visible = false


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("slot_clicked", slot_index)

	# Public API: set visual state for playable (enough energy)
func set_playable(enabled: bool) -> void:
	# subtle tint for playable vs dim for not-playable
	if enabled:
		itemDisplay.modulate = Color(1,1,1,1)
	else:
		itemDisplay.modulate = Color(0.6,0.6,0.6,1)

	# Public API: select/deselect slot (glowing pulse when selected)
func set_selected(selected: bool) -> void:
	# stop existing tween if any
	if name_tween and name_tween.is_valid():
		name_tween.kill()
		name_tween = null
	if selected:
		# create a pulsing tween on modulate to simulate glow
		name_tween = create_tween()
		name_tween.set_loops()
		name_tween.tween_property(itemDisplay, "modulate", Color(0.8,0.9,1,1), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		name_tween.tween_property(itemDisplay, "modulate", Color(1,1,1,1), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		itemDisplay.modulate = Color(1,1,1,1)

func _on_mouse_entered():
	# Smoothly scale up when hovered
	var t = create_tween()
	# Animate the inner itemDisplay instead of the whole slot/panel. Container layouts
	# (GridContainer) control the slot position, so moving the slot itself causes
	# layout reflows and visual stacking. Animating the child control avoids that.
	t.tween_property(itemDisplay, "scale", Vector2(2, 2), 0.12)
	t.tween_property(itemDisplay, "position", _orig_item_pos + Vector2(0, -8), 0.12)
	# show cost on hover
	if cost_label:
		cost_label.visible = true

func _on_mouse_exited():
	# Scale back down
	var t = create_tween()
	t.tween_property(itemDisplay, "scale", Vector2(1.5, 1.5), 0.12)
	t.tween_property(itemDisplay, "position", _orig_item_pos, 0.12)
	# hide cost when not hovered
	if cost_label:
		cost_label.visible = false

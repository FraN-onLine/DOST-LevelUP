extends Panel

@onready var itemDisplay = $CenterContainer/Panel/itemDisplay
var name_tween: Tween = null
var _orig_item_pos: Vector2

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

func update(invslot: slot):
	if !invslot.item:
		itemDisplay.visible = false
	else:
		itemDisplay.visible = true
		itemDisplay.texture = invslot.item.texture
		# Count is no longer tracked on slots — hide count label
		if $CountLabel:
			$CountLabel.visible = false


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("lol")
		emit_signal("slot_clicked", slot_index)

func _on_mouse_entered():
	# Smoothly scale up when hovered
	var t = create_tween()
	# Animate the inner itemDisplay instead of the whole slot/panel. Container layouts
	# (GridContainer) control the slot position, so moving the slot itself causes
	# layout reflows and visual stacking. Animating the child control avoids that.
	t.tween_property(itemDisplay, "scale", Vector2(2, 2), 0.12)
	t.tween_property(itemDisplay, "position", _orig_item_pos + Vector2(0, -8), 0.12)

func _on_mouse_exited():
	# Scale back down
	var t = create_tween()
	t.tween_property(itemDisplay, "scale", Vector2(1.5, 1.5), 0.12)
	t.tween_property(itemDisplay, "position", _orig_item_pos, 0.12)

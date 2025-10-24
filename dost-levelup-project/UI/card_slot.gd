extends Panel

@onready var itemDisplay = $CenterContainer/Panel/itemDisplay
var name_tween: Tween = null

signal slot_clicked(slot_index)

@export var slot_index: int = -1

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Connect mouse enter/exit to create hover animation
	if has_signal("mouse_entered"):
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	if has_signal("mouse_exited"):
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func update(invslot: slot):
	if !invslot.item:
		itemDisplay.visible = false
		$CountLabel.visible = false
	else:
		itemDisplay.visible = true
		itemDisplay.texture = invslot.item.texture
		if invslot.amount > 1:
			$CountLabel.text = str(invslot.amount)
			$CountLabel.visible = true
		else:
			$CountLabel.visible = false


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("lol")
		emit_signal("slot_clicked", slot_index)

func _on_mouse_entered():
	# Smoothly scale up when hovered
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)

func _on_mouse_exited():
	# Scale back down
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1, 1), 0.12)

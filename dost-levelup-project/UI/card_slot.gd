extends Panel

@onready var itemDisplay = $CenterContainer/Panel/itemDisplay
@onready var nameLabel = $Label
var name_tween: Tween = null

signal slot_clicked(slot_index)

@export var slot_index: int = -1

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func update(invslot: slot):
	if !invslot.item:
		itemDisplay.visible = false
		nameLabel.visible = false
		nameLabel.text = ""
		$CountLabel.visible = false
	else:
		itemDisplay.visible = true
		itemDisplay.texture = invslot.item.texture
		nameLabel.text = invslot.item.name
		nameLabel.visible = false
		if invslot.amount > 1:
			$CountLabel.text = str(invslot.amount)
			$CountLabel.visible = true
		else:
			$CountLabel.visible = false
func show_name():
	nameLabel.visible = true
	nameLabel.modulate = Color(1, 1, 1, 1)
	if name_tween and name_tween.is_running():
		name_tween.kill()
	name_tween = create_tween()
	name_tween.tween_property(nameLabel, "modulate", Color(1, 1, 1, 0.3), 1.2)
	name_tween.tween_callback(Callable(self, "_hide_name"))

func _hide_name():
	nameLabel.visible = false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("lol")
		emit_signal("slot_clicked", slot_index)

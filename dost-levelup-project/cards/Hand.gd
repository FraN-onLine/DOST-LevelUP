extends Resource

class_name Hand

signal slot_updated

@export var slots: Array[slot]

func insert(item: Card):
	for s in slots:
		if s.item == null:
			s.item = item
			emit_signal("slot_updated")
			return

# Inventory.gd
func remove_from_slot(slot_index: int):
		slots[slot_index].item = null
		emit_signal("slot_updated")

extends Resource

class_name Hand

signal slot_updated

@export var slots: Array[slot]

func insert(item: Card):
	for s in slots:
		if s.item == item:
			s.amount += 1
			emit_signal("slot_updated")
			return
	# If not found, add to first empty slot
	for s in slots:
		if s.item == null:
			s.item = item
			s.amount = 1
			emit_signal("slot_updated")
			return

# Inventory.gd
func remove_one_from_slot(slot_index: int):
	if slots[slot_index].amount > 1:
		slots[slot_index].amount -= 1
	else:
		slots[slot_index].item = null
		slots[slot_index].amount = 0
	emit_signal("slot_updated")

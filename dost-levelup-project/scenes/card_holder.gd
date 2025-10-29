extends Control

var current_selected = -1

# Called when the node enters the scene tree for the first time.
func deselect_other_slots(selected_index: int) -> void:
	current_selected = selected_index
	print("Deselecting other slots except index ", selected_index)
	for slot in $GridContainer.get_children():
			if slot.slot_index != selected_index:
				slot.set_selected(false)
				

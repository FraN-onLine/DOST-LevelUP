extends TextureButton

var plot_index = [0, 0]
var current_building = null
var is_occupied = false
var building_scene = null

func check_occupied():
	return is_occupied

func _process(delta):
	if is_occupied:
		if building_scene == null:
			var children = get_children()
			for c in children:
				if c.is_in_group("buildings"):
					building_scene = c
					c.plot_index = plot_index
					print(building_scene)
					break
		
func trigger_disaster(card_id: int, disaster_instance):
	print("disaster go breeeeeeeeeeeeeee")
	if is_occupied and building_scene:
		match card_id:
			9: #black_out
				print("blackout")
				building_scene.blackout()
				print("Building at ", plot_index, " is now disabled due to Blackout.") 

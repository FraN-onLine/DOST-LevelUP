extends TextureButton

var plot_index = [0, 0]
var current_building = null
var is_occupied = false
var building_scene = null
var adjacent_plot_indices = [] #all adjacent plots, max of 8

func check_occupied():
	return is_occupied

func set_plot_index(index: Array) -> void:
	plot_index = index
	# Calculate adjacent plots
	adjacent_plot_indices.clear()
	for x_offset in range(-1, 1):
		for y_offset in range(-1, 1):
			if x_offset == 0 and y_offset == 0:
				continue
			var adjacent_index = [plot_index[0] + x_offset, plot_index[1] + y_offset]
			adjacent_plot_indices.append(adjacent_index)

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
			10: #earthquake 3x3 aree
				print("urttth")
				for adj_index in adjacent_plot_indices:
					var parent_node = get_parent().get_parent()
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.current_building:
						tile.current_building.take_damage(30, "quake")
				building_scene.take_damage(30, "quake")
				print("Building at ", plot_index, " took earthquake damage.")
			11: #strike 3x3 aree
				print("urttth")
				for adj_index in adjacent_plot_indices:
					var parent_node = get_parent().get_parent()
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.current_building:
						tile.current_building.take_damage(30, "fire")
				building_scene.take_damage(30, "fire")
				print("Building at ", plot_index, " took fire damage.")

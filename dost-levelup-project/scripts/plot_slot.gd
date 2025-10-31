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
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			if x_offset == 0 and y_offset == 0:
				continue
			if plot_index[0] + x_offset < 0 or plot_index[1] + y_offset < 0:
				continue
			if plot_index[0] + x_offset > 4 or plot_index[1] + y_offset > 4:
				continue
			var adjacent_index = [plot_index[0] + x_offset, plot_index[1] + y_offset]
			adjacent_plot_indices.append(adjacent_index)
	print("adj plots")
	print(adjacent_plot_indices)

func trigger_disaster(card_id: int, disaster_instance):
	print("disaster go breeeeeeeeeeeeeee")
	if is_occupied and building_scene:
		match card_id:
			9: #black_out
				print("blackout")
				building_scene.blackout()
				print("Building at ", plot_index, " disabled") 
			10: #earthquake 3x3 aree
				print("urttth")
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "quakes")
				building_scene.take_damage(30, "quakes")
			11: #strike 3x3 aree
				print("fire")
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "fire")
				building_scene.take_damage(30, "fire")

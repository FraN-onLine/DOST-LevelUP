extends TextureButton

var plot_index = [0, 0]
var current_building = null
var is_occupied = false
var building_scene = null
var adjacent_plot_indices = [] #all adjacent plots, max of 8
var board_owner = ""

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
				await get_tree().create_timer(0.8).timeout
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "quakes")
				building_scene.take_damage(30, "quakes")

			11: #strike 3x3 aree
				print("fire")
				await get_tree().create_timer(0.8).timeout
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "fire")
				building_scene.take_damage(30, "fire")

			12: # tornado

				await get_tree().create_timer(0.8).timeout

				if building_scene:
					building_scene.take_damage(5, "wind")
					print("Tornado damaged building at ", plot_index)

				await get_tree().create_timer(0.8).timeout

				var roll: int
				if multiplayer.is_server():
					roll = randi_range(1, 100)
					if board_owner == "player":
						# The tornado occured towards host, so other player shows it at opponent board
						var opponent_tile = get_tree().root.get_node("Game/OpponentPlot").get_tile_at(plot_index)
						opponent_tile.rpc("sync_tornado_roll", roll)
					else:
						# The tornado occured towards client, so host shows it at player board
						var player_tile = get_tree().root.get_node("Game/PlayerPlot").get_tile_at(plot_index)
						player_tile.rpc("sync_tornado_roll", roll)
					# Host also processes the roll	
					sync_tornado_roll(roll)
				else:
					return # clients will wait for host to send roll


@rpc("reliable")
func sync_tornado_roll(roll: int):
	
	var card_res = ResourceLoader.load("res://cards/card_12.tres")
	var disaster_scene = card_res.disaster_scene

	if roll <= 30:
		if adjacent_plot_indices.size() > 0:
			var parent_node = get_parent().get_parent()
			var new_index = adjacent_plot_indices.pick_random()
			print("Tornado spreads to ", new_index)
			var target_tile = parent_node.get_tile_at(new_index)
			if target_tile:
				var disaster_instance = disaster_scene.instantiate()
				target_tile.add_child(disaster_instance)
				await get_tree().create_timer(0.3).timeout
				target_tile.trigger_disaster(12, disaster_instance)
	elif roll <= 60:
		print("Tornado dissipates at ", plot_index)
	else:
		print("Tornado continues raging at ", plot_index)
		await get_tree().create_timer(0.8).timeout
		var disaster_instance = disaster_scene.instantiate()
		self.add_child(disaster_instance)
		trigger_disaster(12, disaster_instance)

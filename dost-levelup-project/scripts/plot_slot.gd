extends TextureButton

@onready var hover = $PanelContainer

var plot_index = [0, 0]
var current_building = null
var is_occupied = false
var building_scene = null
var adjacent_plot_indices = [] # all adjacent plots, max of 8
var board_owner = ""

func _ready() -> void:
	# Ensure hover panel exists
	hover = get_node_or_null("PanelContainer")
	if not hover:
		push_error("Plot slot is missing PanelContainer for hover!")
		return
		
	# Connect mouse signals
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func on_mouse_entered() -> void:
	if hover and building_scene and is_occupied:
		# Only show hover if there's a building
		# First update the label's text
		if hover.has_node("VBoxContainer/Label"):
			hover.get_node("VBoxContainer/Label").text = building_scene.name
		if hover.has_node("VBoxContainer/HPLabel"):
			hover.get_node("VBoxContainer/HPLabel").text = "HP: %d/%d" % [building_scene.hp, building_scene.max_hp]
		if hover.has_node("VBoxContainer/EnergyLabel"):
			hover.get_node("VBoxContainer/EnergyLabel").text = "Energy: %d" % building_scene.energy_consumption
		
		# Store building data if needed
		var building_data = {
			"name": building_scene.name,
			"hp": building_scene.hp,
			"max_hp": building_scene.max_hp,
			"energy": building_scene.energy_consumption
		}
		hover.toggle(true)

func on_mouse_exited() -> void:
	if hover:
		hover.toggle(false)

func check_occupied():
	return is_occupied

func set_plot_index(index: Array) -> void:
	plot_index = index
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

func trigger_disaster(card_id: int, disaster_instance):
		match card_id:
			9: #blackout
				if is_occupied and building_scene:
					building_scene.blackout()
			10: #area 3x3 quakey
				await get_tree().create_timer(0.8).timeout
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "quakes")
				if is_occupied and building_scene:
					building_scene.take_damage(30, "quakes")
			11: #area 3x3 meterorrer
				await get_tree().create_timer(0.8).timeout
				var parent_node = get_parent().get_parent()
				for adj_index in adjacent_plot_indices:
					var tile = parent_node.get_tile_at(adj_index)
					if tile and tile.is_occupied and tile.building_scene:
						tile.building_scene.take_damage(30, "fire")
				if is_occupied and building_scene:
					building_scene.take_damage(30, "fire")
			12: #townaddooooooo
				await get_tree().create_timer(0.8).timeout
				if is_occupied and building_scene:
					building_scene.take_damage(5, "wind")

				await get_tree().create_timer(0.8).timeout

				if multiplayer.is_server():
					var roll = randi_range(1, 100)
					var new_index = []
					if roll <= 35 and adjacent_plot_indices.size() > 0:
						new_index = adjacent_plot_indices.pick_random()
					if board_owner == "player":
						var opponent_tile = get_tree().root.get_node("Game/OpponentPlot").get_tile_at(plot_index)
						opponent_tile.rpc("sync_tornado_roll", roll, new_index)
					else:
						var player_tile = get_tree().root.get_node("Game/PlayerPlot").get_tile_at(plot_index)
						player_tile.rpc("sync_tornado_roll", roll, new_index)
					sync_tornado_roll(roll, new_index)
				else:
					return


@rpc("reliable")
func sync_tornado_roll(roll: int, new_index: Array):
	var card_res = ResourceLoader.load("res://cards/card_12.tres")
	var disaster_scene = card_res.disaster_scene

	if roll <= 35: #35% chance to move it 
		if new_index.size() == 2:
			var parent_node = get_parent().get_parent()
			var target_tile = parent_node.get_tile_at(new_index)
			if target_tile:
				var disaster_instance = disaster_scene.instantiate()
				target_tile.add_child(disaster_instance)
				await get_tree().create_timer(0.3).timeout
				target_tile.trigger_disaster(12, disaster_instance)
	elif roll <= 60: # 25% chance to goney
		# dissipate
		pass
	else: #hahahaha again!!!!
		await get_tree().create_timer(0.8).timeout
		var disaster_instance = disaster_scene.instantiate()
		self.add_child(disaster_instance)
		trigger_disaster(12, disaster_instance)

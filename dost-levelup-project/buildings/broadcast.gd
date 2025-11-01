extends Building

class_name BroadcastTower

var _buffed_positions := []
# Reducing wind damage by 0.5 (50% less damage)
const WIND_BUFF := -0.5

func init_stats():
	max_hp = 150
	hp = max_hp
	fire_resistance = 1.0    # Takes full fire damage
	wind_resistance = 0.7    # Takes 70% wind damage
	water_resistance = 1.0   # Takes full water damage
	sturdiness = 1.0        # Takes full earthquake damage
	attack = 0
	production_rate = 0
	energy_consumption = 10

	#trigger_effect()

func _process(delta):
	pass

func trigger_effect(delta):
	if not get_parent() or not get_parent().has_method("get_tile_at"):
		return
	for x in range(plot_index[0] - 1, plot_index[0] + 2):
		for y in range(plot_index[1] - 1, plot_index[1] + 2):
			var pos = Vector2(x, y)
			var tile = get_parent().get_tile_at(pos)
			if not tile:
				continue
			if _buffed_positions.has(pos):
				continue
			var current = tile.get("wind_resistance")
			if current == null:
				tile.set("wind_resistance", 1.0)  # Start at full damage
			# Subtract WIND_BUFF to reduce damage taken
			tile.set("wind_resistance", tile.get("wind_resistance") + WIND_BUFF)
			_buffed_positions.append(pos)

#func _exit_tree():
#	_revert_wind_buff()

#func _revert_wind_buff():
#	if not get_parent() or not get_parent().has_method("get_tile_at"):
#		return
#	for pos in _buffed_positions:
#		var tile = get_parent().get_tile_at(pos)
#		if not tile:
#			continue
#		var current = tile.get("wind_resistance")
#		if current != null:
#			tile.set("wind_resistance", current - WIND_BUFF)
#	_buffed_positions.clear()

#func take_damage(amount):
#	hp -= amount
#	if hp <= 0:
#		_revert_wind_buff()
#		queue_free()

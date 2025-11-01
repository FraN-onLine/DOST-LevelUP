extends Building

class_name SeismicReinforcementLab

var _buffed_positions = []
const EARTH_BUFF = 0.5

func _ready():
	max_hp = 150
	hp = max_hp
	# Stored values are "vulnerability": 1.0 = full damage taken, 0.0 = immune.
	# So sturdiness = 0.7 means actual protection = 30%.
	fire_resistance = 1
	wind_resistance = 1
	water_resistance = 1
	sturdiness = 0.7
	attack = 0
	production_rate = 0
	energy_consumption = 10

	trigger_effect()

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
			# Treat tile.sturdiness as vulnerability (1.0 = full damage).
			var current = tile.get("sturdiness")
			if current == null:
				# default missing tiles to full vulnerability
				current = 1.0
				tile.set("sturdiness", current)
			# Apply +50% protection -> reduce vulnerability by EARTH_BUFF (clamped 0..1)
			var new_vuln = clamp(current - EARTH_BUFF, 0.0, 1.0)
			tile.set("sturdiness", new_vuln)
			_buffed_positions.append(pos)

#func _exit_tree():
#	_revert_earth_buff()

#func _revert_earth_buff():
#	if not get_parent() or not get_parent().has_method("get_tile_at"):
#		return
#	for pos in _buffed_positions:
#		var tile = get_parent().get_tile_at(pos)
#		if not tile:
#			continue
#		var current = tile.get("sturdiness")
#		if current == null:
#			continue
		# Revert: increase vulnerability back (clamped 0..1)
#		var reverted = clamp(current + EARTH_BUFF, 0.0, 1.0)
#		tile.set("sturdiness", reverted)
#	_buffed_positions.clear()

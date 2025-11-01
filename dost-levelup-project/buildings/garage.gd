extends Building

var heal_timer = 0
var heal_cooldown = 5


func _ready():
	max_hp = 80
	hp = max_hp
	fire_resistance = 1.0    # Takes full fire damage
	wind_resistance = 0.7    # Takes 70% wind damage
	water_resistance = 1.0   # Takes full water damage
	sturdiness = 1.0        # Takes full earthquake damage
	attack = 0
	production_rate = 0
	energy_consumption = 10

# this is called every secon! trigger effect func
func trigger_effect(delta: float) -> void:
	heal_timer += delta
	if heal_timer > heal_cooldown:
		heal_timer = 0
		#heal 4 adjacent buildings by 10, or something 
		var tile = get_parent().get_parent().get_parent().get_tile_at([plot_index[0],plot_index[1] + 1])
		if tile:
			if tile.building_scene:
				print("heal")
				tile.building_scene.repair_building(10)
		tile = get_parent().get_parent().get_parent().get_tile_at([plot_index[0],plot_index[1] - 1])
		if tile:
			if tile.building_scene:
				print("heal")
				tile.building_scene.repair_building(10)
		tile = get_parent().get_parent().get_parent().get_tile_at([plot_index[0] + 1,plot_index[1]])
		if tile:
			if tile.building_scene:
				print("heal")
				tile.building_scene.repair_building(10)
		tile = get_parent().get_parent().get_parent().get_tile_at([plot_index[0] - 1,plot_index[1]])
		if tile:
			if tile.building_scene:
				print("heal")
				tile.building_scene.repair_building(10)

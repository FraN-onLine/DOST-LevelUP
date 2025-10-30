extends Building

class_name WaterPump

func _ready():
	max_hp = 120
	hp = max_hp
	fire_resistance = 0.5
	wind_resistance = 1
	water_resistance = 0
	sturdiness = 1
	attack = 0
	production_rate = 5
	energy_consumption = 2
	
func _process(delta):
	#for every tile adjacent to the water pump, increase fire resistance
	for x in range (plot_index[0]-1, plot_index[0]+1):
		for y in range (plot_index[1]-1, plot_index[1]+1):
			pass
			#var tile = get_parent().get_tile_at(Vector2(x,y)), get tile at is not yet defined
			#if tile:
			#	tile.fire_resistance = tile.fire_resistance * 0.8 #reduce fire damage by 20%

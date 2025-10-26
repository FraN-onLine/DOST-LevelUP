extends Building

class_name WaterPump

func _ready():
	max_hp = 120
	hp = hp
	var fire_resistance = 1 
	var wind_resistance = 1
	var water_resistance = 1
	var sturdiness = 1 #earthquake/disruption res
	var attack = 0
	var production_rate = 0
	var energy_consumption = 0

func action():
	pass

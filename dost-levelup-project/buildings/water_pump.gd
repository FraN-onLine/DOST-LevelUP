extends Building

class_name WaterPump

const WATER_PRODUCTION_RATE := 5.0  # Water units per second
var stored_water := 0.0
const MAX_WATER_STORAGE := 100.0

func _ready():
	max_hp = 120
	hp = max_hp
	fire_resistance = 1.0    # Takes full fire damage
	wind_resistance = 1.0    # Takes full wind damage
	water_resistance = 0.3   # Takes 30% water damage (70% resistant)
	sturdiness = 1.0        # Takes full earthquake damage
	attack = 0
	production_rate = WATER_PRODUCTION_RATE
	energy_consumption = 10

func _process(delta):
	if stored_water < MAX_WATER_STORAGE:
		stored_water = min(stored_water + (WATER_PRODUCTION_RATE * delta), MAX_WATER_STORAGE)

# Called by other buildings to request water
func request_water(amount: float) -> float:
	if stored_water >= amount:
		stored_water -= amount
		return amount
	else:
		var available = stored_water
		stored_water = 0
		return available

# Returns current water level (for UI display)
func get_water_level() -> float:
	return stored_water

#func take_damage(amount):
#	hp -= amount
#	if hp <= 0:
#		queue_free()

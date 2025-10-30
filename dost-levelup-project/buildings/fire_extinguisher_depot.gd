extends Building

class_name FireExtinguisherDepot

const FIRE_DAMAGE := 10.0  # Damage per second to fires
const COMBAT_RADIUS := 2   # blocks away
const WATER_USAGE := 2.0   # Water used per second when fighting fires
const MAX_WATER_STORAGE := 50.0
const WATER_REQUEST_AMOUNT := 20.0  # Amount to request when refilling

var stored_water := MAX_WATER_STORAGE
var nearest_water_pump: WaterPump = null

func _ready():
    max_hp = 100
    hp = max_hp
    fire_resistance = 0.7    # Takes 70% fire damage (30% resistant)
    wind_resistance = 1.0    # Takes full wind damage
    water_resistance = 1.0   # Takes full water damage
    sturdiness = 1.0        # Takes full earthquake damage
    attack = FIRE_DAMAGE
    production_rate = 0
    energy_consumption = 15

    _find_nearest_water_pump()

func _process(delta):
    if stored_water < WATER_REQUEST_AMOUNT and nearest_water_pump:
        var received = nearest_water_pump.request_water(WATER_REQUEST_AMOUNT)
        stored_water += received
    
    _combat_fires(delta)

func _combat_fires(delta):
    if not get_parent() or not get_parent().has_method("get_tile_at"):
        return
    
    for x in range(plot_index[0] - COMBAT_RADIUS, plot_index[0] + COMBAT_RADIUS + 1):
        for y in range(plot_index[1] - COMBAT_RADIUS, plot_index[1] + COMBAT_RADIUS + 1):
            if stored_water <= 0:
                return  # Out of water, can't fight fires
                
            var pos = Vector2(x, y)
            var tile = get_parent().get_tile_at(pos)
            
            if not tile:
                continue
                
            var fire = tile.get("fire")  # Assuming fires are stored in tiles
            if not fire:
                continue
                
            # Fight the fire
            var water_needed = WATER_USAGE * delta
            if stored_water >= water_needed:
                stored_water -= water_needed
                # Damage the fire
                fire.take_damage(FIRE_DAMAGE * delta)

func _find_nearest_water_pump():
    if not get_parent():
        return
        
    var shortest_distance = INF
    var pumps = get_tree().get_nodes_in_group("water_pumps")  # Assuming water pumps are in this group
    
    for pump in pumps:
        var distance = plot_index.distance_to(pump.plot_index)
        if distance < shortest_distance:
            shortest_distance = distance
            nearest_water_pump = pump

func get_water_level() -> float:
    return stored_water

func take_damage(amount):
    hp -= amount
    if hp <= 0:
        queue_free()
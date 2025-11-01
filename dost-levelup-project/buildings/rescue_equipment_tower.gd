extends Building

class_name RescueEquipmentTower

const REPAIR_RATE := 5.0  # HP restored per second
const REPAIR_RADIUS := 2  # blocks away

func _ready():
    max_hp = 100
    hp = max_hp
    fire_resistance = 1
    wind_resistance = 1
    water_resistance = 1
    sturdiness = 1
    attack = 0
    production_rate = 0
    energy_consumption = 15

func _process(delta):
    _repair_nearby_buildings(delta)

func trigger_effect(delta):
    if not get_parent() or not get_parent().has_method("get_tile_at"):
        return
        
    # Check all tiles in a (2r+1)x(2r+1) square
    for x in range(plot_index[0] - REPAIR_RADIUS, plot_index[0] + REPAIR_RADIUS + 1):
        for y in range(plot_index[1] - REPAIR_RADIUS, plot_index[1] + REPAIR_RADIUS + 1):
            var pos = Vector2(x, y)
            var tile = get_parent().get_tile_at(pos)
            
            if not tile:
                continue
                
            # Get building on tile if any
            var building = tile.get("building")
            if not building:
                continue
                
            # Skip if building is at full health
            if building.hp >= building.max_hp:
                continue
                
            # Apply repair
            var heal_amount = REPAIR_RATE * delta
            building.hp = min(building.hp + heal_amount, building.max_hp)

#func take_damage(amount):
#    hp -= amount
#    if hp <= 0:
#        queue_free()
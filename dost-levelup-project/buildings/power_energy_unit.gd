extends Building

class_name PowerEnergyUnit

func _ready():
    max_hp = 100
    hp = max_hp
    fire_resistance = 1
    wind_resistance = 1
    water_resistance = 1
    sturdiness = 1
    attack = 0
    production_rate = 1
    energy_consumption = 10

    # optional: register in group as well
    add_to_group("buildings")

func trigger_effect(delta):
    # add production_rate per second to the global/network energy rate
    var net = get_node_or_null("/root/Network")
    if net and net.has_method("add_energy"):
        # if network exposes a helper
        net.add_energy(production_rate * delta)
    elif net and net.has_variable("energy_rate"):
        net.energy_rate += production_rate * delta

#func take_damage(amount):
#    hp -= amount
#    if hp <= 0:
#        queue_free()
#   else:
#        pass
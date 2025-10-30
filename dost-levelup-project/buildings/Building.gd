extends Node2D

class_name Building

@export var max_hp: int = 100
var hp: int

# 1 is full damage, if they resist will be lower
var fire_resistance = 1 
var wind_resistance = 1
var water_resistance = 1
var sturdiness = 1 #earthquake/disruption res
var attack = 0
var production_rate = 0
var energy_consumption = 0
var plot_index = [0,0] #this is the index of the current building
var disabled = false 

#var level = 0

var owner_peer_id: int = 0

signal destroyed(owner_peer_id)

func _init():
	hp = max_hp

func take_damage(amount: int, damage_type: String) -> void:
	if damage_type == "fire":
		hp = max(0, hp - (amount * fire_resistance))
	elif damage_type == "water":
		hp = max(0, hp - (amount * water_resistance))
	elif damage_type == "wind":
		hp = max(0, hp - (amount * wind_resistance))
	elif damage_type == "quakes":
		hp = max(0, hp - (amount * sturdiness))
	else: 
		hp = max(0, hp - amount)
	if hp == 0:
		emit_signal("destroyed", owner_peer_id)

func repair(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func is_alive() -> bool:
	return hp > 0

func on_tick(delta: float) -> void:
	# Override in subclasses for periodic effects
	pass
	
func destroy():
	pass

func interact(actor_id: int) -> void:
	# Override to perform actions when player interacts with the building
	pass

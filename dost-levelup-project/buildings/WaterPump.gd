extends "res://buildings/Building.gd"

class_name WaterPump

@export var production_rate: int = 1

func _ready():
	# Custom setup for water pump
	pass

func on_tick(delta: float) -> void:
	# Example: produce resources or affect nearby tiles
	# For now it's a no-op placeholder
	pass

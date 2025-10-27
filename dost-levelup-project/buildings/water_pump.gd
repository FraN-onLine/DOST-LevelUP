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
	
	# Visual setup
	_setup_visual()

func _setup_visual():
	# Load the water pump sprite
	var sprite = Sprite2D.new()
	add_child(sprite)
	
	# Try to load texture from building scene
	if ResourceLoader.exists("res://buildings/WaterPump_Station.png"):
		var texture = ResourceLoader.load("res://buildings/WaterPump_Station.png")
		sprite.texture = texture

func action():
	print("WaterPump action - Producing water at rate: ", production_rate)
	# Override for specific water pump actions

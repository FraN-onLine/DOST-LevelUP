extends TextureButton

var plot_index = [0, 0]
var current_building = null
var is_occupied = false
var building_scene = null

func check_occupied():
	return is_occupied

func process(delta):
	if is_occupied:
		if not building_scene:
			var children = get_children()
			for c in children:
				if c.is_in_group("buildings"):
					building_scene = c
					c.plot_index = plot_index
					break
		
		

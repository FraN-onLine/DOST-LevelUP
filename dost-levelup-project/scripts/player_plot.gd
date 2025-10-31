extends Control

signal plot_clicked(plot_index)

@export var is_player_plot: bool = true

func get_tile_at(index):
	#get grid container then get the plot at index
	for btn in $GridContainer.get_children():
		if btn.plot_index == index:
			return btn
	return null

extends Control

signal plot_clicked(plot_index)

@export var plot_index: Vector2 = Vector2.ZERO #represents the index of the plot in the grid
@export var is_player_plot: bool = true

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	#in the grid is a 5x5 grid of plots, each plot is a Control node
	#when there is a card selected and this an empty plot is tapped, with sufficient energy, place the builfing
	#for every button in the grid, connect the signal to the parent grid to handle placement

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_player_plot:
			print("Plot ", plot_index, " clicked")
			emit_signal("plot_clicked", plot_index) #plot index like (0,0), (1,0), etc

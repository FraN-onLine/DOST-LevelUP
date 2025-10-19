extends Control

func _on_server_pressed():
	Network.start_server()
	get_tree().change_scene("res://scenes/lobby.tscn")

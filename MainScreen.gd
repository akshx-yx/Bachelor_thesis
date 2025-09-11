extends Node2D

@export var next_level: PackedScene
@onready var fader= $fader

func _on_start_pressed():
	fader.fade_screen(true, 0.5, func(): 
		get_tree().change_scene_to_file("res://level_select.tscn") )

func _on_exit_pressed():
	fader.fade_screen(true, 1.0, func(): 
		get_tree().quit() )


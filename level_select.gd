extends Control
@onready var scene_tree =get_tree()
@onready var fader= $fader
func _ready():
	print("Full save path: ", ProjectSettings.globalize_path("user://savegame.data"))
	File_Manager.load_game()
	call_deferred("connect_level_selected_to_level_box")
	if OnscreenUi.level_data.is_empty():
		setup_level_box()
	else:
		for box in $TextureRect/Levelgrid.get_children():
			var level_num = box.get_index() + 1
			box.level_num = level_num
			box.locked = OnscreenUi.level_data.get(level_num, true) and level_num != 1


func setup_level_box() ->void:
	for box in $TextureRect/Levelgrid.get_children():
		box.level_num= box.get_index()+1
		box.locked=true
	$TextureRect/Levelgrid.get_child(0).locked=false

func change_to_scene(level_num:int)->void:
	OnscreenUi.curr_level=level_num
	fader.fade_screen(true, 1.0, func(): scene_tree.change_scene_to_file("res://Levels/Level_" +str(level_num)+ ".tscn"))

func connect_level_selected_to_level_box() -> void:
	for box in $TextureRect/Levelgrid.get_children(): box.connect("level_selected", change_to_scene)

func _on_home_button_pressed():
	scene_tree.change_scene_to_file("res://MainScreen.tscn")

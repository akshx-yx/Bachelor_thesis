extends Node

class_name  FileManager

const save_path =  "user://savegame.data"

func save() ->Dictionary:
	var save_dict = {
		"level_data": OnscreenUi.level_data
	}
	return save_dict

func save_game():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_var(call("save"))
	print(" Game saved to:", save_path)

func load_game():
	if not FileAccess.file_exists(save_path):
		File_Manager.save_game()
		return
	
	var save_file = FileAccess.open(save_path,FileAccess.READ)
	var saved_data = save_file.get_var()
	
	OnscreenUi.level_data = {} if saved_data["level_data"].is_empty() else saved_data["level_data"]
	

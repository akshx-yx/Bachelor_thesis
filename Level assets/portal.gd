extends Area2D

@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
const file_begin = "res://Levels/Level_"

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var current_scene_file = get_tree().current_scene.scene_file_path
		var level_str = current_scene_file.get_file().get_basename().replace("Level_", "")
		var current_level = level_str.to_int()
		OnscreenUi.level_data[current_level] = false
		File_Manager.save_game()
		print("LEVEL DATA:", OnscreenUi.level_data)
		if current_level == 7:
			await get_tree().create_timer(0.5).timeout  # Wait 2 seconds
			get_tree().change_scene_to_file("res://MainScreen.tscn")
		else:
			# ✅ Go to next level
			var next_level_path = "res://Levels/Level_" + str(current_level + 1) + ".tscn"
			get_tree().change_scene_to_file(next_level_path)
		
func _ready():
	anim.play("spin")

func activate_portal():
	visible = true
	$CollisionShape2D.disabled = false

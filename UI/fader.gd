extends ColorRect

var fade_tween: Tween

func _ready():
	self.visible=false

func fade_screen(fade_to_black: bool , duration: float, callback: Callable) -> void:
	self.visible=true
	var fader_color =1.0 if fade_to_black else 0.0
	
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	fade_tween= get_tree().create_tween()
	fade_tween.tween_property(self, "modulate:a", fader_color, duration)
	
	await fade_tween.finished
	if callback:
		callback.call()

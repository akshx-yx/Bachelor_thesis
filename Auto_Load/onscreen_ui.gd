@tool
extends Node
var playerBody: CharacterBody2D
signal level_completed

var curr_level: int=0
var level_data: Dictionary= {}
var completed_levels: Array = []
#player
var playerAlive: bool
var playerDamageZone: Area2D
var playerDamageAmount: int 

# enemies
var waterDamageZone: Area2D
var waterDamageAmount: int

var airDamageZone: Area2D
var airDamageAmount: int

var fireDamageZone: Area2D
var fireDamageAmount: int

var earthDamageZone: Area2D
var earthDamageAmount: int

# boss
var waterbossDamageAmount: int
var waterbossDamageZone: Area2D

var firebossDamageAmount: int
var firebossDamageZone: Area2D

var earthbossDamageAmount: int
var earthbossDamageZone: Area2D

func mark_level_complete(level_num: int):
	if not level_data.has(level_num) or not level_data[level_num]:
		level_data[level_num] = true
		File_Manager.save_game()
		emit_signal("level_completed", level_num)

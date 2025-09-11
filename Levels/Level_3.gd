extends Node2D

@onready var portal = $portal
@onready var boss = $water_boss 
var portal_activated = false

func _ready():
	# Only Level 3 hides the portal at start
	portal.visible = false
	portal.get_node("CollisionShape2D").disabled = true

func _process(_delta):
	if portal_activated:
			return  # Already handled
	elif is_instance_valid(boss) and boss.dead:
		print("Boss defeated. Activating portal.")
		portal.activate_portal()
		portal_activated = true

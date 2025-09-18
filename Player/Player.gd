extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var deal_damage_zone = $dealdamagezone
@onready var idle_y_position = sprite.position.y

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_type: String
var current_attack: bool
var attack_equip: bool = true # For testing
var damage_applied: bool = false
var dead: bool = false
var health = 100
var health_max = 100
var health_min = 0
var can_take_damage: bool= true
var fall_limit_y = 1000

func _ready():
	OnscreenUi.playerBody = self
	current_attack = false
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	OnscreenUi.playerDamageZone = deal_damage_zone

	if current_attack:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if global_position.y > fall_limit_y:
		handle_fall_out_of_bounds()

	# Flip damage zone with player
	if sprite.flip_h:
		$dealdamagezone.scale.x = -abs($dealdamagezone.scale.x) # Ensure positive scale
	else:
		$dealdamagezone.scale.x = abs($dealdamagezone.scale.x) # Flip it to negative

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if not current_attack:
			anim.play("Jump")

	# Horizontal movement + flipping
	if !dead:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction == -1:
			sprite.flip_h = true
		elif direction == 1:
			sprite.flip_h = false

		# Handle movement animations only if not attacking
		if not current_attack:
			if direction != 0:
				velocity.x = direction * SPEED
				if velocity.y == 0:
					anim.play("Run")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if velocity.y == 0:
					anim.play("Idle")
			if velocity.y > 0:
				anim.play("Fall")

	# Handle attack input
	if attack_equip and not current_attack:
		if Input.is_action_just_pressed("atk_water"):
			trigger_attack("atk_water")
		elif Input.is_action_just_pressed("atk_air"):
			trigger_attack("atk_air")
		elif Input.is_action_just_pressed("atk_earth"):
			trigger_attack("atk_earth")
		elif Input.is_action_just_pressed("atk_fire"):
			trigger_attack("atk_fire")

	check_hitbox()
	move_and_slide()

func trigger_attack(attack: String):
	current_attack = true
	attack_type = attack
	await get_tree().create_timer(0.05).timeout # Small delay before attack starts
	handle_attack_animation(attack_type)
	set_damage(attack_type)

func handle_attack_animation(attack_type: String):
	if not anim.has_animation(attack_type):
		return

	# Apply Y-offset *before* animation starts to prevent jump
	match attack_type:
		"atk_water":
			sprite.position.y = -2 # Try -22, -25, etc. until it feels grounded
		"atk_fire":
			sprite.position.y = -4
		"atk_earth":
			sprite.position.y = -5
		"atk_air":
			sprite.position.y = -20 
		_:
			sprite.position.y = -5

	# Now play the animation
	anim.play(attack_type)
	toggle_damage_collisions(attack_type)

func toggle_damage_collisions(attack_type):
	var damage_zone_collision = deal_damage_zone.get_node("CollisionShape2D")
	damage_applied = false # Reset for new attack
	damage_zone_collision.disabled = false
	# Wait for a very short moment (one physics frame) to register collision
	await get_tree().create_timer(0.05).timeout
	# Immediately disable the collision after applying damage
	damage_zone_collision.disabled = true

func _on_animation_finished(anim_name: String):
	if anim_name.begins_with("atk_"):
		current_attack = false
		sprite.position.y = idle_y_position # Reset properly

func set_damage(attack_type):
	var current_damage_to_deal: int
	if attack_type == "atk_water":
		current_damage_to_deal = 25
	elif attack_type == "atk_fire":
		current_damage_to_deal = 40
	elif attack_type == "atk_earth":
		current_damage_to_deal = 25
	elif attack_type == "atk_air":
		current_damage_to_deal = 10

	OnscreenUi.playerDamageAmount = current_damage_to_deal

func check_hitbox():
	var damage: int
	var overlapping_areas = $dealdamagezone.get_overlapping_bodies()
	for body in overlapping_areas:
		if body.is_in_group("Airenemy") and body.can_take_damage:
			damage = OnscreenUi.airDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		elif body.is_in_group("Waterenemy") and body.can_take_damage:
			damage = OnscreenUi.waterDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		elif body.is_in_group("Fireenemy") and body.can_take_damage:
			damage = OnscreenUi.fireDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		elif body.is_in_group("Earthenemy") and body.can_take_damage:
			damage = OnscreenUi.earthDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		
		elif body.is_in_group("Waterboss") and body.can_take_damage:
			damage = OnscreenUi.waterbossDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		elif body.is_in_group("Fireboss") and body.can_take_damage:
			damage = OnscreenUi.firebossDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)
		elif body.is_in_group("Earthboss") and body.can_take_damage:
			damage = OnscreenUi.earthbossDamageAmount
			body.take_damage(damage)
			body.take_damage_cooldown(0.5)


func take_damage(damage: int): 
	if not can_take_damage or dead or damage <= 0: 
		return 

	# ✨ IMPORTANT: cancel any ongoing attack so _physics_process doesn't early-return
	if current_attack:
		current_attack = false
		# (optional safety) disable the attack hitbox immediately
		var damage_zone_collision = deal_damage_zone.get_node("CollisionShape2D")
		if damage_zone_collision:
			damage_zone_collision.disabled = true

	health -= damage
	can_take_damage = false 
	damage_applied = true 
	anim.play("Take_hit")

	print("Player hit! Current health: ", health) 

	if health <= 0: 
		health = 0 
		dead = true 
		OnscreenUi.playerAlive = false 
		handle_death_animation() 
	else: 
		take_damage_cooldown(1.0)


func handle_death_animation():
	velocity.x= 0
	anim.play("Death")
	await get_tree().create_timer(3.5).timeout
	get_tree().change_scene_to_file("res://level_select.tscn")

func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

func handle_fall_out_of_bounds():
	if dead:
		return 
	dead = true
	get_tree().change_scene_to_file("res://level_select.tscn")

extends CharacterBody2D
class_name WaterBoss

@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Enemy stats
var health = 350
var health_max = 350
var health_min = 0
var dead: bool = false
var taking_damage: bool = false

var speed = 40
var damage_to_deal = 40
var enraged: bool = false
var enrage_threshold := 0.5
var enrage_speed_multiplier := 1.5
var enrage_damage_multiplier := 1.5
var enrage_cooldown_multiplier := 0.5


# AI ranges
var detection_range = 150 
var attack_range = 70 
var attack_cooldown = 1.5 
var last_attack_time = 0.0

# Internal flags
var attacking: bool = false
var player: CharacterBody2D

func _ready():
	player = OnscreenUi.playerBody
	anim.animation_finished.connect(_on_animation_finished)

func _process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	if sprite.flip_h:
		$HitBox.scale.x = abs($HitBox.scale.x)
	else:
		$HitBox.scale.x = -abs($HitBox.scale.x)
	if player != null and not dead:
		handle_ai(delta)
		
	print("Health:", health, "Enraged:", enraged)


	handle_animation()
	move_and_slide()

# --- AI logic ---
func handle_ai(delta):
	if attacking or taking_damage:
		velocity.x = 0
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range:
		velocity.x = 0
	elif distance_to_player > attack_range:
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity.x = dir_to_player.x * speed
	else:
		velocity.x = 0
		try_attack()

# --- Attack ---
func try_attack():
	if player == null:
		return

	var current_time = Time.get_ticks_msec() / 1000.0  
	if current_time - last_attack_time < attack_cooldown:
		return 

	last_attack_time = current_time
	attacking = true
	anim.play("Attack") 

func apply_attack_damage():
	var overlapping_areas = $HitBox.get_overlapping_bodies()
	for body in overlapping_areas:
		if body.is_in_group("Player") and body.can_take_damage:
			body.take_damage(damage_to_deal)
			body.take_damage_cooldown(0.5)	
			break # prevent hitting multiple times


# --- Animations ---
func handle_animation():
	if dead:
		velocity.x = 0
		anim.play("Death")
		await get_tree().create_timer(anim.current_animation_length).timeout 
		queue_free()
	elif taking_damage:
		anim.play("Take_Hit")
		await get_tree().create_timer(anim.current_animation_length).timeout
		taking_damage = false
	elif attacking:
		pass
	elif velocity.x != 0:
		anim.play("Run")
		sprite.flip_h = velocity.x > 0
	else:
		anim.play("Idle")


func take_damage(damage):
	if dead or taking_damage:
		return

	
	if attacking:
		attacking = false
		# Optionally stop the attack animation immediately
		if anim.current_animation == "Attack":
			anim.stop()

	health -= damage
	taking_damage = true
	anim.play("Take_Hit")

	# Enrage check
	if not enraged and float(health) <= float(health_max) * enrage_threshold:
		enrage()

	if health <= 0:
		health = 0
		dead = true
		print("WaterBoss defeated!")

	print(str(self), " current health:", health)

	
func enrage():
	enraged = true
	print("WaterBoss is enraged! Buffs activated!")

	# Apply stat buffs
	speed *= enrage_speed_multiplier
	damage_to_deal = int(damage_to_deal * enrage_damage_multiplier)
	attack_cooldown *= enrage_cooldown_multiplier

func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
	elif anim_name.begins_with("Take_Hit"):
		taking_damage = false

func _on_hurt_box_area_entered(area):
	if area == OnscreenUi.playerDamageZone:
		take_damage(OnscreenUi.playerDamageAmount)

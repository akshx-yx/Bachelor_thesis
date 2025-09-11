extends CharacterBody2D
class_name FireEnemy

@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Enemy stats
var health = 100
var health_max = 100
var health_min = 0
var dead: bool = false
var taking_damage: bool = false

var speed = 40
var damage_to_deal = 40

# AI ranges
var detection_range = 150  # Enemy starts chasing player if within this distance
var attack_range = 50      # Enemy attacks if within this distance
var attack_cooldown = 1.5  # Seconds between attacks
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
		$DealDamage.scale.x = -abs($DealDamage.scale.x)
	else:
		$DealDamage.scale.x = abs($DealDamage.scale.x)
	# Only run AI if player exists
	
	if player != null and not dead:
		handle_ai(delta)

	handle_animation()
	move_and_slide()

# --- AI logic ---
func handle_ai(delta):
	if attacking or taking_damage:
		velocity.x = 0
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range:
		# Player out of detection range → idle
		velocity.x = 0
	elif distance_to_player > attack_range:
		# Player detected but not close enough → chase
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity.x = dir_to_player.x * speed
	else:
		# Player is in attack range → attack
		velocity.x = 0
		try_attack()

# --- Attack ---
func try_attack():
	if player == null:
		return

	var current_time = Time.get_ticks_msec() / 1000.0  # Godot 4 replacement
	if current_time - last_attack_time < attack_cooldown:
		return  # Still in cooldown

	last_attack_time = current_time
	attacking = true
	anim.play("Attack")  # Play attack animation

# --- This should be called on the "hit frame" of Attack animation ---
func apply_attack_damage():
	var overlapping_areas = $DealDamage.get_overlapping_bodies()
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
		anim.play("Take_hit")
		await get_tree().create_timer(anim.current_animation_length).timeout
		taking_damage = false
	elif attacking:
		# Keep attack animation playing
		pass
	elif velocity.x != 0:
		anim.play("Run")
		sprite.flip_h = velocity.x < 0
	else:
		anim.play("Idle")

# --- Enemy takes damage ---
func _on_enemyhitbox_area_entered(area):
	if area == OnscreenUi.playerDamageZone:
		take_damage(OnscreenUi.playerDamageAmount)

func take_damage(damage):
	if dead:
		return
	health -= damage
	taking_damage = true
	if health <= 0:
		health = 0
		dead = true
	print(str(self), "current health:", health)

func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
	elif anim_name.begins_with("Take_hit"):
		taking_damage = false

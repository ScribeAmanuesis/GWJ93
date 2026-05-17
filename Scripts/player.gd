extends CharacterBody2D
class_name Player

enum MovementMode {
	WASD,
	ASTEROIDS
}
var is_invulnerable: bool = false
@export var invulnerability_duration: float = 1.0

var can_shoot: bool = true
var is_dead: bool = false
@onready var bullet_spawn: Marker2D = $Marker2D

signal health_changed(current_health, max_health)

var engine_sfx : AudioStream = preload("res://Sfx/engine.mp3")
var shoot_sfx : AudioStream = preload("res://Sfx/Player Ship Attack.mp3")
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2

@export var bullet_scene: PackedScene = preload("res://Scenes/player_bullet.tscn")
@export var shoot_delay: float = .8
@export var max_health := 10
var health := max_health
var bullet_damage
@onready var engine_player: AudioStreamPlayer = $AudioStreamPlayer

@export var movement_mode: MovementMode = MovementMode.WASD

@export_group("WASD Movement")
@export var move_speed := 300.0

@export_group("Asteroids Movement")
@export var thrust := 600.0
@export var turn_speed := 4.0
@export var max_speed := 500.0
@export var friction := 0.98

# Spine Nodes
@onready var body: SpineSprite = $Body
@onready var cannon: SpineSprite = $Cannon

func apply_upgrades():
	# movement
	move_speed = Global.move_speed
	turn_speed = Global.rotation_speed

	# fire rate
	shoot_delay = max(0.1, 0.8 / Global.fire_rate)

	# damage
	bullet_damage = Global.damage

func _ready() -> void:
	health = Global.player_health
	apply_upgrades()
	# Set initial animation state
	var body_anim_state : = body.get_animation_state()
	body_anim_state.add_animation("ds_idle", 0.0, true)
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.add_animation("ds_cannon_idle", 0.0, true)

func _physics_process(delta: float) -> void:

	move_asteroids(delta)

	if Input.is_action_pressed("ui_accept"):
		shoot()

	move_and_slide()

	var camera := get_viewport().get_camera_2d()

	if camera:

		var screen_size := get_viewport_rect().size / camera.zoom

		var half_width := screen_size.x * 0.5
		var half_height := screen_size.y * 0.5

		var margin := 32.0

		global_position.x = clamp(
			global_position.x,
			camera.global_position.x - half_width + margin,
			camera.global_position.x + half_width - margin
		)

		global_position.y = clamp(
			global_position.y,
			camera.global_position.y - half_height + margin,
			camera.global_position.y + half_height - margin
		)
func shoot():
	if !can_shoot:
		return
	audio_stream_player_2.stream = shoot_sfx
	audio_stream_player_2.play()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.direction = Vector2.UP.rotated(rotation)
	bullet.damage = bullet_damage
	add_sibling(bullet)

	# Change animation state
	var cannon_anim_state : = cannon.get_animation_state()
	#cannon_anim_state.set_animation("ds_cannon_shot", false)
	cannon_anim_state.add_animation("ds_cannon_idle", 0.3, true)

	can_shoot = false
	await get_tree().create_timer(shoot_delay).timeout
	can_shoot = true


#func move_wasd() -> void:
	#var input_direction := Vector2.ZERO
#
	#input_direction.x = Input.get_axis("ui_left", "ui_right")
	#input_direction.y = Input.get_axis("ui_up", "ui_down")
#
	#input_direction = input_direction.normalized()
#
	#velocity = input_direction * move_speed
#
	#look_at(get_global_mouse_position())
	#rotation += deg_to_rad(90)


func move_asteroids(delta: float) -> void:
	var turn_input := Input.get_axis("ui_left", "ui_right")
	rotation += turn_input * turn_speed * delta

	if Input.is_action_pressed("ui_up"):
		if !engine_player.playing:
			engine_player.stream = engine_sfx
			engine_player.play()
		var direction := Vector2.UP.rotated(rotation)
		velocity += direction * thrust * delta
	else:
		engine_player.stop()
	velocity *= friction

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# If velocity is near zero, set to idle, otherwise set to fly
	var body_anim_state : = body.get_animation_state()
	if velocity.length() < 10.0:
		body_anim_state.add_animation("ds_idle", 0.0, true)
	else:
		body_anim_state.add_animation("ds_fly",0.0, true)

func damage(amount: float):
	if is_dead:
		return
	if is_invulnerable:
		return
	health -= amount
	Global.player_health = health
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
		return
	
	is_invulnerable = true
	await get_tree().create_timer(invulnerability_duration).timeout
	is_invulnerable = false
	
	var body_anim_state = body.get_animation_state()
	body_anim_state.set_animation("ds_damaged", false)
	body_anim_state.add_animation("ds_fly", 0.3, true)
	
	
func die():
	if is_dead:
		return

	is_dead = true
	var body_anim_state : = body.get_animation_state()
	body_anim_state.set_animation("ds_defeat")
	cannon.hide()
	await body.animation_completed
	get_tree().change_scene_to_file("res://Scenes/mission_screen.tscn")
	queue_free()

extends CharacterBody2D
class_name Player

enum MovementMode {
	WASD,
	ASTEROIDS
}
var can_shoot: bool = true
@onready var bullet_spawn: Marker2D = $Marker2D

var engine_sfx : AudioStream = preload("res://Sfx/engine.mp3")
@export var bullet_scene: PackedScene = preload("res://Scenes/player_bullet.tscn")
@export var shoot_delay: float = .8
@export var health := 100.0

@onready var engine_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

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

func _ready() -> void:

	# Set initial animation state
	var body_anim_state : = body.get_animation_state()
	body_anim_state.add_animation("ds_idle", 0.0, true)
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.add_animation("ds_cannon_idle", 0.0, true)

func _physics_process(delta: float) -> void:
	#if movement_mode == MovementMode.WASD:
		#move_wasd()
	#elif movement_mode == MovementMode.ASTEROIDS:
	move_asteroids(delta)
	if Input.is_action_pressed("ui_accept"):
		shoot()

	move_and_slide()

func shoot():
	if !can_shoot:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.direction = Vector2.UP.rotated(rotation)
	add_sibling(bullet)

	# Change animation state
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.set_animation("ds_cannon_shot")
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
		sprite_2d.play("moving")
		if !engine_player.playing:
			engine_player.stream = engine_sfx
			engine_player.play()
		var direction := Vector2.UP.rotated(rotation)
		velocity += direction * thrust * delta
	else:
		sprite_2d.animation = "idle"
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
	health -= amount
	if health <= 0:
		die()

func die():
	#TODO: Die animation, sfx and reset run
	var body_anim_state : = body.get_animation_state()
	body_anim_state.set_animation("ds_defeat")
	cannon.hide()
	await body.animation_completed
	queue_free()

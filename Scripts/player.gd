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
		
func damage(amount: float):
	health -= amount
	if health <= 0:
		die()
		
func die():
	#TODO: Die animation, sfx and reset run
	queue_free()

extends CharacterBody2D

signal dying

var is_dead := false
var can_shoot := true
var is_shooting := false

@export var sprite_height := 132.0
@export var health := 150.0
@export var teleport_interval := 5.0
@export var telegraph_duration := 1.5
@export var laser_duration := 2.0

@export var laser_scene: PackedScene = preload("res://Scenes/green_laser.tscn")
@onready var bullet_spawn: Marker2D = $Marker2D

var teleport_timer := 0.0
var target: Player = null
var is_alerting := false

@onready var body: SpineSprite = $Body
@onready var cannon: SpineSprite = $Cannon
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var laser_sound: AudioStream = preload("res://Sfx/Laser Attack2.mp3")
var die_sound: Array[AudioStream] = [
	preload("res://Sfx/explosion 1.mp3"),
	preload("res://Sfx/explosion 2.mp3"),
	preload("res://Sfx/explosion 3.mp3"),
	preload("res://Sfx/explosion 4.mp3"),
]

var max_view := 1500.0
var angle_between_rays := deg_to_rad(5.0)
var view_area := deg_to_rad(360.0)

func _ready() -> void:
	generate_rays()
	teleport_timer = teleport_interval
	var body_anim := body.get_animation_state()
	body_anim.add_animation("gs_idle", 0.0, true)
	var cannon_anim := cannon.get_animation_state()
	cannon_anim.add_animation("gs_cannon_idle", 0.0, true)

func generate_rays() -> void:
	var ray_count := int(view_area / angle_between_rays)
	for i in range(ray_count):
		var ray := RayCast2D.new()
		var angle := angle_between_rays * (i - ray_count / 2.0)
		ray.target_position = Vector2.UP.rotated(angle) * max_view
		add_child(ray)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	target = null
	for child in get_children():
		if child is RayCast2D:
			var ray := child as RayCast2D
			if ray.is_colliding() and ray.get_collider() is Player:
				target = ray.get_collider()
				break

	var sees_player := target != null
	if sees_player and !is_alerting:
		is_alerting = true
		MusicController.enemies_alerted += 1
		MusicController.update_intensity()
	elif !sees_player and is_alerting:
		is_alerting = false
		MusicController.enemies_alerted = max(MusicController.enemies_alerted - 1, 0)
		MusicController.update_intensity()

	if sees_player:
		if !is_shooting:
			var target_rotation := global_position.angle_to_point(target.global_position) + PI / 2
			rotation = target_rotation

		teleport_timer -= delta
		if teleport_timer <= 0.0:
			teleport_timer = teleport_interval
			shoot()

func get_random_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var screen_size := get_viewport_rect().size / camera.zoom
	var margin := 100.0
	
	var attempts := 0
	while attempts < 20:
		var candidate := Vector2(
			camera.global_position.x + randf_range(-screen_size.x / 2.0 + margin, screen_size.x / 2.0 - margin),
			camera.global_position.y + randf_range(-screen_size.y / 2.0 + margin, screen_size.y / 2.0 - margin)
		)
		
		var space := get_world_2d().direct_space_state
		var params := PhysicsPointQueryParameters2D.new()
		params.position = candidate
		params.collision_mask = collision_mask
		var results := space.intersect_point(params)
		
		if results.is_empty():
			return candidate
		attempts += 1
	
	# Se não achar posição livre em 20 tentativas, retorna qualquer uma
	return Vector2(
		camera.global_position.x + randf_range(-screen_size.x / 2.0 + margin, screen_size.x / 2.0 - margin),
		camera.global_position.y + randf_range(-screen_size.y / 2.0 + margin, screen_size.y / 2.0 - margin)
	)
func shoot() -> void:
	if !can_shoot or is_dead or target == null:
		return
	can_shoot = false
	is_shooting = true

	var cannon_anim := cannon.get_animation_state()
	cannon_anim.set_animation("gs_cannon_shot")
	audio_stream_player.stream = laser_sound
	audio_stream_player.play()
	# Fase de charge: segue o player por 3s
	var charge_time := 3.0
	var elapsed := 0.0
	var telegraph := Line2D.new()
	telegraph.width = 3.0
	telegraph.default_color = Color(0.2, 1.0, 0.2, 0.5)
	get_parent().add_child(telegraph)

	while elapsed < charge_time:
		await get_tree().process_frame
		if is_dead:
			telegraph.queue_free()
			is_shooting = false
			return
		elapsed += get_process_delta_time()

		# Atualiza direção do telegraph enquanto segue o player
		if target != null:
			var dir := global_position.direction_to(target.global_position)
			rotation = dir.angle() + PI / 2.0
			var length := get_viewport_rect().size.length()
			telegraph.clear_points()
			telegraph.add_point(global_position)
			telegraph.add_point(global_position + dir * length)

	# Congela direção no momento do disparo
	var shoot_direction := Vector2.UP.rotated(rotation)
	telegraph.queue_free()
	is_shooting = true  # mantém travado

	# Spawna lasers
	var camera := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / camera.zoom
	var laser_length := viewport_size.length() 
	var count := int(ceil(laser_length / sprite_height)) + 2
	var lasers: Array = []

	for i in range(count):
		var laser = laser_scene.instantiate()
		laser.z_index = -1  # atrás do inimigo
		get_parent().add_child(laser)
		laser.global_position = bullet_spawn.global_position + shoot_direction * sprite_height * i
		laser.rotation = shoot_direction.angle() + PI / 2.0
		var spine := laser.get_node("SpineSprite") as SpineSprite
		var anim := spine.get_animation_state()
		anim.add_animation("gs_laserbeam", 0.0, true)
		if i == 0:
			laser.is_main = true
			laser.duration = laser_duration
		lasers.append(laser)

	# Espera laser durar
	await get_tree().create_timer(laser_duration).timeout

	for laser in lasers:
		if is_instance_valid(laser):
			laser.queue_free()

	# Teleporta depois do laser
	global_position = get_random_position()
	is_shooting = false

	cannon_anim.set_animation("gs_cannon_idle")
	await get_tree().create_timer(teleport_interval * 0.5).timeout
	can_shoot = true
	

func damage(amount: float) -> void:
	if is_dead:
		return
	var body_anim := body.get_animation_state()
	body_anim.set_animation("gs_damaged")
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	can_shoot = false

	MusicController.enemies_alerted = max(MusicController.enemies_alerted - 1, 0)
	MusicController.update_intensity()

	dying.emit()
	set_physics_process(false)
	velocity = Vector2.ZERO
	cannon.visible = false

	audio_stream_player.stream = die_sound.pick_random()
	audio_stream_player.play()

	var body_anim := body.get_animation_state()
	body_anim.set_animation("gs_defeat", false)

	var anim = body.get_skeleton().get_data().find_animation("gs_defeat")
	var duration = anim.get_duration()
	await get_tree().create_timer(duration).timeout
	queue_free()

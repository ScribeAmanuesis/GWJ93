extends CharacterBody2D
# class_name Enemy


var suspected_direction := Vector2.ZERO
var is_suspicious := false
var suspicion_time := 0.0
@export var suspicion_duration := 2
var suspected_target_pos := Vector2.ZERO  # NOVO

signal dying
var target: Player = null
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var die_sound : Array[AudioStream] = [
	preload("res://Sfx/explosion 1.mp3"), 
	preload("res://Sfx/explosion 2.mp3"), 
	preload("res://Sfx/explosion 3.mp3"), 
	preload("res://Sfx/explosion 4.mp3")
	]
@export var desired_distance := 800.0
@export var distance_tolerance := 60.0
@export var distance_correction_strength := 2.0
@export var max_radial_speed := 220.0

@export var obstacle_distance := 250.0
@export var obstacle_avoid_speed := 450.0

var is_dead := false
var can_shoot := true
var is_alerting := false

@onready var bullet_spawn: Marker2D = $Marker2D
@export var bullet_scene: PackedScene = preload("res://Scenes/blue_enemy_bullet.tscn")

@export var health := 10.0

@export var max_speed := 520.0
@export var acceleration := 700.0
@export var friction := 400.0

@export var min_orbit_speed := 280.0
@export var max_orbit_speed := 480.0
@export var wander_change_time_min := 1.0
@export var wander_change_time_max := 2.5

var orbit_side := 1.0
var current_orbit_speed := 350.0
var target_orbit_speed := 350.0
var wander_timer := 0.0

var view_area := deg_to_rad(360.0)
@export var max_view := 1500.0
var angle_between_rays := deg_to_rad(5.0)

# Spine Nodes
@onready var body: SpineSprite = $Body
@onready var cannon: SpineSprite = $Cannon


func _ready() -> void:
	generate_rays()
	pick_new_wander()
	var body_anim_state : = body.get_animation_state()
	body_anim_state.add_animation("bs_idle", 0.0, true)
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.add_animation("bs_cannon_idle", 0.0, true)

func generate_rays() -> void:
	var ray_count := int(view_area / angle_between_rays)
	for i in range(ray_count):
		var ray := RayCast2D.new()
		var ray_angle := angle_between_rays * (i - ray_count / 2.0)
		ray.target_position = Vector2.UP.rotated(ray_angle) * max_view
		add_child(ray)

func _physics_process(delta: float) -> void:

	target = null
	var obstacle_avoidance := Vector2.ZERO

	for child in get_children():
		if child is RayCast2D:
			var ray := child as RayCast2D
			if ray.is_colliding():
				var collider := ray.get_collider()
				if collider is Player:
					target = collider
				else:
					var collision_point := ray.get_collision_point()
					var distance_to_obstacle := global_position.distance_to(collision_point)
					if distance_to_obstacle < obstacle_distance:
						var away := collision_point.direction_to(global_position)
						var strength := 1.0 - (distance_to_obstacle / obstacle_distance)
						obstacle_avoidance += away * obstacle_avoid_speed * strength

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
		is_suspicious = false
		shoot()

		var target_rotation := global_position.angle_to_point(target.global_position) + PI / 2
		rotation = target_rotation

		var distance_to_player := global_position.distance_to(target.global_position)
		var direction_to_player := global_position.direction_to(target.global_position)
		var side_direction := direction_to_player.orthogonal()

		wander_timer -= delta
		if wander_timer <= 0.0:
			pick_new_wander()

		current_orbit_speed = move_toward(current_orbit_speed, target_orbit_speed, acceleration * delta)

		var tangential_velocity := side_direction * orbit_side * current_orbit_speed

		var distance_error := distance_to_player - desired_distance
		var radial_speed := 0.0
		if abs(distance_error) > distance_tolerance:
			radial_speed = clamp(distance_error * distance_correction_strength, -max_radial_speed, max_radial_speed)

		var radial_velocity := direction_to_player * radial_speed
		var desired_velocity := tangential_velocity + radial_velocity + obstacle_avoidance

		if desired_velocity.length() > max_speed:
			desired_velocity = desired_velocity.normalized() * max_speed

		velocity = velocity.move_toward(desired_velocity, acceleration * delta)

	elif is_suspicious:
		suspicion_time -= delta

		var dist_to_target := global_position.distance_to(suspected_target_pos)
		var target_rotation := global_position.angle_to_point(suspected_target_pos) + PI / 2
		rotation = rotate_toward(rotation, target_rotation, 5 * delta)

		var speed_scale := 1.0
		if suspicion_time <= 0:
			speed_scale = 0.0
		elif dist_to_target < 200.0:
			speed_scale = dist_to_target / 200.0

		var dir_to_target := global_position.direction_to(suspected_target_pos)
		var desired_velocity := dir_to_target * max_speed * speed_scale

		if obstacle_avoidance.length() > 0:
			var avoid = obstacle_avoidance.normalized() * min(obstacle_avoidance.length(), max_speed)
			var blended = (desired_velocity + avoid).normalized() * max_speed * speed_scale
			velocity = velocity.move_toward(blended, acceleration * delta)
		else:
			velocity = velocity.move_toward(desired_velocity, acceleration * delta)

		if suspicion_time <= 0 and velocity.length() < 10.0:
			is_suspicious = false

	else:
		if obstacle_avoidance != Vector2.ZERO:
			var desired_velocity := obstacle_avoidance
			if desired_velocity.length() > max_speed:
				desired_velocity = desired_velocity.normalized() * max_speed
			velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	var body_anim_state : = body.get_animation_state()
	if velocity.length() < 10.0:
		body_anim_state.add_animation("bs_idle", 0.0, true)
	else:
		body_anim_state.add_animation("bs_fly", 0.0, true)

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

func damage(amount: float):
	var body_anim_state = body.get_animation_state()
	body_anim_state.set_animation("bs_damaged")
	health -= amount
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	can_shoot = false

	MusicController.enemies_alerted -= 1
	MusicController.enemies_alerted = max(MusicController.enemies_alerted, 0)
	MusicController.update_intensity()

	dying.emit()

	set_physics_process(false)
	velocity = Vector2.ZERO
	cannon.visible = false

	audio_stream_player.stream = die_sound.pick_random()
	audio_stream_player.play()

	var body_anim_state := body.get_animation_state()
	body_anim_state.set_animation("bs_defeat", false)

	var anim = body.get_skeleton().get_data().find_animation("bs_defeat")
	var duration = anim.get_duration()
	await get_tree().create_timer(duration).timeout
	queue_free()

func pick_new_wander() -> void:
	wander_timer = randf_range(wander_change_time_min, wander_change_time_max)
	if randf() < 0.25:
		orbit_side *= -1.0
	target_orbit_speed = randf_range(min_orbit_speed, max_orbit_speed)

func shoot():
	if !can_shoot or is_dead:
		return
	can_shoot = false

	audio_stream_player.stream = preload("res://Sfx/Blue Ship Attack.mp3")
	audio_stream_player.play()

	var charge_steps := 5
	var cannon_anim_state := cannon.get_animation_state()
	for step in range(charge_steps):
		print("Charging shoot, step: ", step + 1)
		if step == charge_steps - 1:
			cannon_anim_state.set_animation("bs_cannon_shot")
		await get_tree().create_timer(1.0).timeout
		if is_dead:
			return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.direction = Vector2.UP.rotated(rotation)
	add_sibling(bullet)

	cannon_anim_state.set_animation("bs_cannon_idle")

	await get_tree().create_timer(2.0).timeout
	can_shoot = true

func _on_area_2d_area_entered(area: Area2D) -> void:
	if !area.is_in_group("Bullet"):
		return
	if !area.is_from_player:
		return

	var bullet_dir = area.direction.normalized()
	suspected_direction = bullet_dir
	suspected_target_pos = global_position - bullet_dir * 1000.0

	is_suspicious = true
	suspicion_time = suspicion_duration

extends CharacterBody2D
# class_name Enemy

var suspected_direction := Vector2.ZERO
var is_suspicious := false
var suspicion_time := 0.0
@export var suspicion_duration := 3
var suspected_target_pos := Vector2.ZERO

@onready var marker_right: Marker2D = $MarkerRight
@onready var marker_left: Marker2D = $MarkerLeft
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var die_sound : Array[AudioStream] = [
	preload("res://Sfx/explosion 1.mp3"), 
	preload("res://Sfx/explosion 2.mp3"), 
	preload("res://Sfx/explosion 3.mp3"), 
	preload("res://Sfx/explosion 4.mp3")
	]
var is_dead := false
var target: Player = null
@export var collision_damage := 1.0
@export var knockback_force := 500.0
@export var knockback_time := 0.2
#NOTE: I think the knockback was too weak because of the speed limit, so I added this flag
var is_knocked_back := false

var is_alerting := false

signal dying

@export var bullet_scene: PackedScene = preload("res://Scenes/red_enemy_bullet.tscn")
@export var shoot_cooldown := 2.0
var can_shoot := true
@export var bullet_spread := 10

@export var health := 10.0

@export var turn_speed := 5
@export var max_speed := 300
@export var thrust := 600
@export var friction := 0.98

@export var obstacle_distance := 250.0
@export var obstacle_avoid_speed := 450.0

var view_area := deg_to_rad(360.0)
@export var max_view := 1000.0
var angle_between_rays := deg_to_rad(5.0)

#Spine Nodes
@onready var body: SpineSprite = $Body
@onready var cannon: SpineSprite = $Cannon



func _ready() -> void:
	generate_rays()

	# Set initial animation state
	var body_anim_state : = body.get_animation_state()
	body_anim_state.add_animation("rs_idle", 0.0, true)
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.add_animation("rs_cannon_idle", 0.0, true)

func generate_rays() -> void:
	var ray_count := int(view_area / angle_between_rays)

	for i in range(ray_count):
		var ray := RayCast2D.new()

		var angle := angle_between_rays * (i - ray_count / 2.0)
		ray.target_position = Vector2.UP.rotated(angle) * max_view

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
					var point = ray.get_collision_point()
					var dist = global_position.distance_to(point)
					if dist < obstacle_distance:
						var away = point.direction_to(global_position)
						var strength = 1.0 - (dist / obstacle_distance)
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

	if sees_player and !is_knocked_back:
		is_suspicious = false

		var target_rotation := global_position.angle_to_point(target.global_position) + PI / 2
		rotation = rotate_toward(rotation, target_rotation, 5 * delta)

		var angle_diff := absf(angle_difference(rotation, target_rotation))
		if angle_diff < deg_to_rad(20):
			var dir := Vector2.UP.rotated(rotation)
			velocity += dir * thrust * delta
			shoot()

		velocity += obstacle_avoidance * delta

	elif is_suspicious:
		suspicion_time -= delta

		var dist_to_target := global_position.distance_to(suspected_target_pos)
		var target_rotation := global_position.angle_to_point(suspected_target_pos) + PI / 2
		rotation = rotate_toward(rotation, target_rotation, turn_speed * delta)

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
			velocity = velocity.move_toward(blended, thrust * delta)
		else:
			var body_anim_state : = body.get_animation_state()
			body_anim_state.add_animation("rs_fly")
			velocity = velocity.move_toward(desired_velocity, thrust * delta)

		if suspicion_time <= 0 and velocity.length() < 10.0:
			is_suspicious = false

	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

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
func shoot() -> void:
	if !can_shoot:
		return

	# Right Bullet
	var bullet_right = bullet_scene.instantiate()
	bullet_right.direction = Vector2.UP.rotated(rotation + deg_to_rad(bullet_spread))
	bullet_right.global_position = marker_right.global_position

	# Left Bullet
	var bullet_left = bullet_scene.instantiate()
	bullet_left.global_position = marker_left.global_position
	bullet_left.direction = Vector2.UP.rotated(rotation - deg_to_rad(bullet_spread))

	add_sibling(bullet_right)
	add_sibling(bullet_left)
	audio_stream_player.stream = preload("res://Sfx/red ship shooting single hit.mp3")
	audio_stream_player.play()
	# Change animation state
	var cannon_anim_state : = cannon.get_animation_state()
	cannon_anim_state.set_animation("rs_cannon_shot")
	cannon_anim_state.add_animation("rs_cannon_idle", 0.3, true)

	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func damage(amount: float):
	health -= amount
	if health <= 0:
		die()
		return
	var body_anim_state = body.get_animation_state()
	body_anim_state.set_animation("rs_damaged", false)
	body_anim_state.add_animation("rs_fly",0.3 ,true)

func die():
	if is_dead:
		return

	is_dead = true

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
	body_anim_state.set_animation("rs_defeat", false)

	# pega duração da animação
	var anim = body.get_skeleton().get_data().find_animation("rs_defeat")
	var duration = anim.get_duration()
	await get_tree().create_timer(duration).timeout
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("Player"):
		return
	body.damage(collision_damage)
	var knockback_direction := body.global_position.direction_to(global_position)
	velocity += knockback_direction * knockback_force
	is_knocked_back = true
	await get_tree().create_timer(knockback_time).timeout
	is_knocked_back = false



func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if !area.is_in_group("Bullet"):
		return
	if !area.is_from_player:
		return

	var bullet_dir = area.direction.normalized()
	suspected_direction = bullet_dir
	# Salva o ponto fixo agora, não recalcula todo frame
	suspected_target_pos = global_position - bullet_dir * 1000.0

	is_suspicious = true
	suspicion_time = suspicion_duration

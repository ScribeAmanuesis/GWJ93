extends CharacterBody2D
# class_name Enemy

@onready var marker_right: Marker2D = $MarkerRight
@onready var marker_left: Marker2D = $MarkerLeft

var target: Player = null

@export var bullet_scene: PackedScene = preload("res://Scenes/red_enemy_bullet.tscn")
@export var shoot_cooldown := 2.0
var can_shoot := true
@export var bullet_spread := 10

@export var health := 100.0

@export var turn_speed := 5
@export var max_speed := 350
@export var thrust := 600
@export var friction := 0.98

@export var obstacle_distance := 250.0
@export var obstacle_avoid_speed := 450.0

var view_area := deg_to_rad(360.0)
@export var max_view := 1000.0
var angle_between_rays := deg_to_rad(5.0)

func _ready() -> void:
	generate_rays()

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
					var collision_point := ray.get_collision_point()
					var distance_to_obstacle := global_position.distance_to(collision_point)

					if distance_to_obstacle < obstacle_distance:
						var away_from_obstacle := collision_point.direction_to(global_position)

						# The closer the obstacle is, the stronger the enemy moves away from it.
						var avoid_strength := 1.0 - (distance_to_obstacle / obstacle_distance)
						obstacle_avoidance += away_from_obstacle * obstacle_avoid_speed * avoid_strength

	var does_see_player := target != null

	if does_see_player:
		var target_rotation := global_position.angle_to_point(target.global_position) + PI / 2
		rotation = rotate_toward(rotation, target_rotation, turn_speed * delta)

		var angle_diff: float = absf(angle_difference(rotation, target_rotation))
		if angle_diff < deg_to_rad(20):
			var direction := Vector2.UP.rotated(rotation)
			velocity += direction * thrust * delta
			shoot()

	# Move away from nearby obstacles without changing the current chase behavior.
	velocity += obstacle_avoidance * delta

	velocity *= friction

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	move_and_slide()

func shoot() -> void:
	if !can_shoot:
		return

	# Right Bullet
	var bullet_right = bullet_scene.instantiate()
	bullet_right.global_position = marker_right.global_position
	bullet_right.direction = Vector2.UP.rotated(rotation + deg_to_rad(bullet_spread))

	# Left Bullet
	var bullet_left = bullet_scene.instantiate()
	bullet_left.global_position = marker_left.global_position
	bullet_left.direction = Vector2.UP.rotated(rotation - deg_to_rad(bullet_spread))

	get_tree().current_scene.add_child(bullet_right)
	get_tree().current_scene.add_child(bullet_left)

	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func damage(amount: float):
	health -= amount
	if health <= 0:
		die()
		
func die():
	#TODO: Die animation and sfx
	queue_free()

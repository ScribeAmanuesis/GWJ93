extends CharacterBody2D
# class_name Enemy

var target: Player = null

@export var desired_distance := 800.0
@export var distance_tolerance := 60.0
@export var distance_correction_strength := 2.0
@export var max_radial_speed := 220.0

@export var obstacle_distance := 250.0
@export var obstacle_avoid_speed := 450.0

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

func _ready() -> void:
	generate_rays()
	pick_new_wander()

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
						var away_from_obstacle := collision_point.direction_to(global_position)


						var avoid_strength := 1.0 - (distance_to_obstacle / obstacle_distance)
						obstacle_avoidance += away_from_obstacle * obstacle_avoid_speed * avoid_strength

	if target != null:

		var target_rotation := global_position.angle_to_point(target.global_position) + PI / 2
		rotation = target_rotation

		var distance_to_player := global_position.distance_to(target.global_position)
		var direction_to_player := global_position.direction_to(target.global_position)
		var side_direction := direction_to_player.orthogonal()


		wander_timer -= delta
		if wander_timer <= 0.0:
			pick_new_wander()

		current_orbit_speed = move_toward(
			current_orbit_speed,
			target_orbit_speed,
			acceleration * delta
		)

		var tangential_velocity := side_direction * orbit_side * current_orbit_speed

		var distance_error := distance_to_player - desired_distance
		var radial_speed := 0.0

		if abs(distance_error) > distance_tolerance:
			radial_speed = clamp(
				distance_error * distance_correction_strength,
				-max_radial_speed,
				max_radial_speed
			)

		var radial_velocity := direction_to_player * radial_speed

		var desired_velocity := tangential_velocity + radial_velocity + obstacle_avoidance

		if desired_velocity.length() > max_speed:
			desired_velocity = desired_velocity.normalized() * max_speed

		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		if obstacle_avoidance != Vector2.ZERO:
			var desired_velocity := obstacle_avoidance

			if desired_velocity.length() > max_speed:
				desired_velocity = desired_velocity.normalized() * max_speed

			velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

func pick_new_wander() -> void:
	wander_timer = randf_range(wander_change_time_min, wander_change_time_max)

	if randf() < 0.25:
		orbit_side *= -1.0

	target_orbit_speed = randf_range(min_orbit_speed, max_orbit_speed)

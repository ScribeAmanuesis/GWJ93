extends CharacterBody2D
class_name Enemy

var target: Player = null


@export var turn_speed = 5
@export var max_speed = 350
@export var thrust = 600
@export var friction := 0.98
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

	for child in get_children():
		if child is RayCast2D:
			var ray := child as RayCast2D

			if ray.is_colliding() and ray.get_collider() is Player:
				target = ray.get_collider()
				break

	var does_see_player := target != null
	if does_see_player:
		var target_rotation = global_position.angle_to_point(target.global_position) + (PI)/2
		rotation = rotate_toward(rotation, target_rotation, turn_speed * delta)

		var angle_diff = abs(angle_difference(rotation, target_rotation))
		if angle_diff < deg_to_rad(20):
			var direction = Vector2.UP.rotated(rotation)
			velocity += direction * thrust * delta

	velocity *= friction
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	move_and_slide()

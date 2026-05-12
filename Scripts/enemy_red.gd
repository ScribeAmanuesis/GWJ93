extends CharacterBody2D
# class_name Enemy

@onready var marker_right: Marker2D = $MarkerRight
@onready var marker_left: Marker2D = $MarkerLeft

var target: Player = null
@export var collision_damage := 10.0
@export var knockback_force := 500.0
@export var knockback_time := 0.2
#NOTE: I think the knockback was too weak because of the speed limit, so I added this flag
var is_knocked_back := false

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
					var collision_point := ray.get_collision_point()
					var distance_to_obstacle := global_position.distance_to(collision_point)

					if distance_to_obstacle < obstacle_distance:
						var away_from_obstacle := collision_point.direction_to(global_position)

						# The closer the obstacle is, the stronger the enemy moves away from it.
						var avoid_strength := 1.0 - (distance_to_obstacle / obstacle_distance)
						obstacle_avoidance += away_from_obstacle * obstacle_avoid_speed * avoid_strength

	var does_see_player := target != null

	if does_see_player and !is_knocked_back:
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

	# If velocity is near zero, set to idle, otherwise set to fly
	var body_anim_state : = body.get_animation_state()
	if velocity.length() < 10.0:
		body_anim_state.add_animation("rs_idle", 0.0, true)
	else:
		body_anim_state.add_animation("rs_fly",0.0, true)

	if !is_knocked_back and velocity.length() > max_speed:
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

	add_sibling(bullet_right)
	#get_tree().current_scene.add_child(bullet_right
	add_sibling(bullet_left)
	#get_tree().current_scene.add_child(bullet_left)

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

func die():
	#TODO: Die animation and sfx
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

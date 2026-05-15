extends Node2D

@onready var entities: Node2D = $Entities
@onready var asteroids: Node2D = $Asteroids

@export var enemy_red_scene: PackedScene = preload("res://Scenes/enemy_red.tscn")


@export var spawn_offset_y := -1200.0    
@export var spawn_range_y := 100.0
@export var spawn_range_x := 2000.0
@export var min_distance_from_player := 500.0
@export var min_distance_between_entities := 800.0


@export var wave_count := 3
@export var enemies_per_wave := 2 * Global.level[0] 
@export var enemy_spawn_interval := 1.0
@export var wave_delay := 6.0


var player: Player = null
var current_wave := 0
var enemies_alive := 0
var spawned_positions: Array[Vector2] = []


func _ready() -> void:
	MusicController.play_music()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	start_next_wave()




func start_next_wave() -> void:
	if current_wave >= wave_count:
		level_complete()
		return

	current_wave += 1
	spawned_positions.clear() 
	print("=== Wave %d / %d ===" % [current_wave, wave_count])
	spawn_enemies_staggered(enemies_per_wave)


func on_enemy_died() -> void:
	enemies_alive -= 1
	print("Enemies: %d" % enemies_alive)
	if enemies_alive <= 0:
		print("Wave %d complete!" % current_wave)
		await get_tree().create_timer(wave_delay).timeout
		start_next_wave()




func spawn_enemies_staggered(count: int) -> void:
	for i in range(count):
		await get_tree().create_timer(enemy_spawn_interval * i).timeout
		spawn_single_enemy()


func spawn_single_enemy() -> void:
	var enemy = enemy_red_scene.instantiate()
	enemy.global_position = get_spawn_position()
	spawned_positions.append(enemy.global_position)
	enemy.connect("dying", on_enemy_died)
	entities.add_child(enemy)
	enemies_alive += 1




func get_spawn_position() -> Vector2:
	var attempts := 40
	var best_pos := Vector2.ZERO
	var best_score := -INF


	var player_y := player.global_position.y if player != null else 0.0
	var center_y := player_y + spawn_offset_y
	best_pos = Vector2(0.0, center_y)

	for _i in range(attempts):
		var pos := Vector2(
			randf_range(-spawn_range_x, spawn_range_x),
			center_y + randf_range(-spawn_range_y, spawn_range_y)
		)

		if player != null and pos.distance_to(player.global_position) < min_distance_from_player:
			continue

		var too_close_to_asteroid := false
		for asteroid in asteroids.get_children():
			if pos.distance_to(asteroid.global_position) < min_distance_between_entities:
				too_close_to_asteroid = true
				break
		if too_close_to_asteroid:
			continue

		var dist_others := INF
		for other_pos in spawned_positions:
			dist_others = min(dist_others, pos.distance_to(other_pos))

		var score := dist_others if spawned_positions.size() > 0 else 999999.0
		if score > best_score:
			best_score = score
			best_pos = pos

		if best_score >= min_distance_between_entities:
			break

	return best_pos




func level_complete() -> void:
	print("Level complete!")
	# TODO: Transition to the next level / victory screen

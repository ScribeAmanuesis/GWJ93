extends HBoxContainer

@export var full_texture: Texture2D
@export var empty_texture: Texture2D
@export var max_health := 10

func criar_coracao() -> TextureRect:
	var heart = TextureRect.new()
	heart.custom_minimum_size = Vector2(32, 32)
	heart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # ← não estica pra preencher o HBox
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.expand_mode = TextureRect.EXPAND_KEEP_SIZE        # ← respeita o minimum_size
	heart.texture = empty_texture
	return heart

func _ready():
	for i in range(max_health):
		add_child(criar_coracao())

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		print("Player não encontrado")
		return

	player.health_changed.connect(update_hearts)
	update_hearts(player.health, player.max_health)

func update_hearts(current_health: int, p_max_health: int):
	while get_child_count() < p_max_health:
		add_child(criar_coracao())

	while get_child_count() > p_max_health:
		get_child(get_child_count() - 1).free()

	for i in range(p_max_health):
		get_child(i).texture = full_texture if i < current_health else empty_texture

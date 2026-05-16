extends Area2D

@export var speed := 700.0
@export var damage := 10.0
var direction := Vector2.UP
var is_from_player := false


@onready var spine_sprite: SpineSprite = $SpineSprite

func _ready() -> void:
	var anim_state :  = spine_sprite.get_animation_state()
	anim_state.set_animation("rs_laser", true, 0)
	print(global_position)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	global_rotation = direction.angle()



func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.damage(damage)
		queue_free()
	elif body.is_in_group("Bullet"):
		return
	else:
		queue_free()

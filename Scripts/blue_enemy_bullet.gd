extends Area2D

@export var speed := 600.0
@export var damage := 20.0
var direction := Vector2.UP



func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		body.damage(damage)
		queue_free()
	else:
		queue_free()

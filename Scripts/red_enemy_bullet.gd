extends Area2D

@export var speed := 700.0
var direction := Vector2.UP



func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	

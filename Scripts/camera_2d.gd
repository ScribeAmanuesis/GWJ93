extends Camera2D

@export var speed := 80

func _process(delta):
	position.y -= speed * delta

extends Area2D

@export var sprite_height := 132.0
@export var damage_per_second := 80.0
@export var duration := 2.0

var lifetime := 0.0
var is_main := false  # só o nó principal controla o tempo

func _process(delta: float) -> void:
	if !is_main:
		return
	lifetime += delta
	if lifetime >= duration:
		queue_free()

func _physics_process(delta: float) -> void:
	if !is_main:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			body.damage(damage_per_second * delta)

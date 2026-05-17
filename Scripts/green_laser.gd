extends Area2D

@export var damage_per_second := 1.0
@export var duration := 1.0

var lifetime := 0.0
var is_main := false
var player_inside: Player = null


func _process(delta: float) -> void:
	if is_main:
		lifetime += delta
		if lifetime >= duration:
			queue_free()
	if player_inside:
		player_inside.damage(damage_per_second)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = body


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null

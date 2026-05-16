extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicController.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_btn_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/mission_screen.tscn")


func _on_options_btn_button_up() -> void:
	pass # Replace with function body.


func _on_credits_btn_button_up() -> void:
	pass # Replace with function body.

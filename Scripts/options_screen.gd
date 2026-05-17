extends Node2D

@export var main_volume: HSlider
@export var music_volume: HSlider
@export var effects_volume: HSlider
@export var effects_player: AudioStreamPlayer2D
@export var back_button: Button

func _ready() -> void:
	main_volume.value = AudioServer.get_bus_volume_db(0)
	music_volume.value = AudioServer.get_bus_volume_db(1)
	effects_volume.value = AudioServer.get_bus_volume_db(2)

func _on_main_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, main_volume.value)

func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, music_volume.value)

func _on_effects_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, effects_volume.value)

func _on_effects_volume_drag_ended(value_changed: bool) -> void:
	effects_player.play()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

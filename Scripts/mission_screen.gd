extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicController.stop()
	fill_missions()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_difficulty_text(value: int) -> String:
	match value:
		1:
			return "Easy"
		2:
			return "Medium"
		3:
			return "Hard"
		_:
			return "Unknown"
			
func get_waves_text(value: int) -> String:
	match value:
		1:
			return "3"
		2:
			return "4"
		3:
			return "5"
		_:
			return "Unknown"


func fill_missions():

	# Red
	$Missions/Red/Mission.text = "Mission: %d/3" % Global.level[0]
	$Missions/Red/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[0])
	$Missions/Red/Waves.text = "Waves: %s" % get_waves_text(Global.level[0])
	$Missions/Red/Reward.text = "Reward"

	# Green
	$Missions/Green/Mission.text = "Mission: %d/3" % Global.level[1]
	$Missions/Green/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[1])
	$Missions/Green/Waves.text = "Waves: %s" % get_waves_text(Global.level[1])
	$Missions/Green/Reward.text = "Reward"

	# Blue
	$Missions/Blue/Mission.text = "Mission: %d/3" % Global.level[2]
	$Missions/Blue/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[2])
	$Missions/Blue/Waves.text = "Waves: %s" % get_waves_text(Global.level[2])
	$Missions/Blue/Reward.text = "Reward"
	

func _on_button_red_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/red_mission.tscn")


func _on_button_blue_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/blue_mission.tscn")


func _on_button_green_button_up() -> void:
	pass # Replace with function body.


func _on_button_shop_button_up() -> void:
	pass # Replace with function body.

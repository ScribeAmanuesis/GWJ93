extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if MusicController.get_music() != 4:
		MusicController.stop()
		MusicController.play_music(4)
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
	
	var red_description := ""
	
	match Global.level[0]:
		1:
			red_description = "We are testing our new ships. On you."
		2:
			red_description = "Impressive. We improved them further."
		3:
			red_description = "Our last test. Prepare as good as you can."
			
	$Missions/Red/Mission.text = "Mission: %d/3" % Global.level[0]
	$Missions/Red/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[0])
	$Missions/Red/Waves.text = "Waves: %s" % get_waves_text(Global.level[0])
	$Missions/Red/Description.text = red_description
	
	var green_description := ""
	match Global.level[1]:
		1:
			green_description = "Face our new laser technologies and be rewarded*\n*only in case you'll survive."
		2:
			green_description = "We have been studying our failures. We have a new strategy (more ships)."
		3:
			green_description = "Wonderful. Prepare for the final test."
			
	$Missions/Green/Mission.text = "Mission: %d/3" % Global.level[1]
	$Missions/Green/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[1])
	$Missions/Green/Waves.text = "Waves: %s" % get_waves_text(Global.level[1])
	$Missions/Green/Description.text = green_description
	
	
	
	var blue_description := ""
	match Global.level[2]:
		1:
			blue_description = "We require your assistance in being our shooting target. Fighting back is allowed."
		2:
			blue_description = "We once again require your assistance. All the weak spots have been improved."
		3:
			blue_description = "We require your assistance for the final time. Come prepared."
	$Missions/Blue/Mission.text = "Mission: %d/3" % Global.level[2]
	$Missions/Blue/Difficulty.text = "Difficulty: %s" % get_difficulty_text(Global.level[2])
	$Missions/Blue/Waves.text = "Waves: %s" % get_waves_text(Global.level[2])
	$Missions/Blue/Description.text = blue_description
	

func _on_button_red_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/red_mission.tscn")


func _on_button_blue_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/blue_mission.tscn")


func _on_button_green_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/green_mission.tscn")


func _on_button_shop_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/shop.tscn")

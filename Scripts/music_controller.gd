extends Node

@export_range(0.0, 1.0)
var intensity := 0.0

var target_intensity := 0.0

var menu_music = preload("res://Sfx/Music/Menus/GWJ93 - Main Menu.ogg")
var shop_music = preload("res://Sfx/Music/Menus/GWJ93 - Shop.ogg")


var red_layers: Array[AudioStream] = [
	preload("res://Sfx/Music/Red/GWJ93 - Red A.ogg"),
	preload("res://Sfx/Music/Red/GWJ93 - Red B.ogg"),
	preload("res://Sfx/Music/Red/GWJ93 - Red C.ogg")
]
var green_layers: Array[AudioStream] = [
	preload("res://Sfx/Music/Green/GWJ93 - Green A.ogg"),
	preload("res://Sfx/Music/Green/GWJ93 - Green B.ogg"),
	preload("res://Sfx/Music/Green/GWJ93 - Green C.ogg")
]

var blue_layers: Array[AudioStream] = [
	preload("res://Sfx/Music/Blue/GWJ93 - Blue A.ogg"),
	preload("res://Sfx/Music/Blue/GWJ93 - Blue B.ogg"),
	preload("res://Sfx/Music/Blue/GWJ93 - Blue C.ogg")
]

@onready var layer1: AudioStreamPlayer = $Layer1
@onready var layer2: AudioStreamPlayer = $Layer2
@onready var layer3: AudioStreamPlayer = $Layer3

var music: int
var enemies_alerted := 0

func stop():

	layer1.stop()
	layer2.stop()
	layer3.stop()
	
	intensity = 0.0
	target_intensity = 0.0
	enemies_alerted = 0
	
func play_music(_music: int):
	music = _music
	stop()
	match music:
		1:
			layer1.stream = red_layers[0]
			layer2.stream = red_layers[1]
			layer3.stream = red_layers[2]
			layer1.play()
			layer2.play()
			layer3.play()
		2:
			layer1.stream = blue_layers[0]
			layer2.stream = blue_layers[1]
			layer3.stream = blue_layers[2]
			layer1.play()
			layer2.play()
			layer3.play()
		3:
			layer1.stream = green_layers[0]
			layer2.stream = green_layers[1]
			layer3.stream = green_layers[2]
			layer1.play()
			layer2.play()
			layer3.play()
		4:
			layer1.stream = menu_music
			layer1.play()
		5:
			layer1.stream = shop_music
			layer1.play()

func _ready():

	#layer1.play()
	#layer2.play()
	#layer3.play()

	update_mix(true)


func _process(delta):

	intensity = lerpf(intensity, target_intensity, delta * 2.0)

	update_mix(false, delta)


func update_intensity():

	target_intensity = clamp(enemies_alerted * 0.5, 0.0, 1.0)


func update_mix(force := false, delta := 0.0):

	var l1 = 0.8
	var l2 = smoothstep(0.2, 0.6, intensity)
	var l3 = smoothstep(0.6, 1.0, intensity)

	var sum = l1 + l2 + l3

	if sum < 0.001:
		sum = 0.001

	l1 /= sum
	l2 /= sum
	l3 /= sum

	l1 *= 1.2

	var total2 = l1 + l2 + l3
	l1 /= total2
	l2 /= total2
	l3 /= total2

	var target1 = linear_to_db(max(l1, 0.001))
	var target2 = linear_to_db(max(l2, 0.001))
	var target3 = linear_to_db(max(l3, 0.001))

	if force:
		layer1.volume_db = target1
		layer2.volume_db = target2
		layer3.volume_db = target3
	else:
		layer1.volume_db = move_toward(layer1.volume_db, target1, delta * 30.0)
		layer2.volume_db = move_toward(layer2.volume_db, target2, delta * 30.0)
		layer3.volume_db = move_toward(layer3.volume_db, target3, delta * 30.0)
		
func get_music() -> int:
	return music

extends Node

@export_range(0.0, 1.0)
var intensity := 0.0

var target_intensity := 0.0

@export var master_volume := -18.0

@onready var layer1: AudioStreamPlayer = $Layer1
@onready var layer2: AudioStreamPlayer = $Layer2
@onready var layer3: AudioStreamPlayer = $Layer3

var enemies_alerted := 0

func stop():

	layer1.stop()
	layer2.stop()
	layer3.stop()

	intensity = 0.0
	target_intensity = 0.0
	enemies_alerted = 0
	
func play_music():

	if !layer1.playing:
		layer1.play()

	if !layer2.playing:
		layer2.play()

	if !layer3.playing:
		layer3.play()

func _ready():

	layer1.play()
	layer2.play()
	layer3.play()

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

	# soma total de energia ativa
	var sum = l1 + l2 + l3

	# evita explosão quando tudo toca junto
	if sum < 0.001:
		sum = 0.001

	# normaliza energia total (ESSENCIAL)
	l1 /= sum
	l2 /= sum
	l3 /= sum

	# opcional: “peso musical” pra layer1 continuar dominante
	l1 *= 1.2

	# clamp final pra não quebrar
	var total2 = l1 + l2 + l3
	l1 /= total2
	l2 /= total2
	l3 /= total2

	var target1 = linear_to_db(max(l1, 0.001)) + master_volume
	var target2 = linear_to_db(max(l2, 0.001)) + master_volume
	var target3 = linear_to_db(max(l3, 0.001)) + master_volume

	if force:
		layer1.volume_db = target1
		layer2.volume_db = target2
		layer3.volume_db = target3
	else:
		layer1.volume_db = move_toward(layer1.volume_db, target1, delta * 30.0)
		layer2.volume_db = move_toward(layer2.volume_db, target2, delta * 30.0)
		layer3.volume_db = move_toward(layer3.volume_db, target3, delta * 30.0)

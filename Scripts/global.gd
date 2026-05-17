extends Node

# R, B, G
var level : Array[int] = [1, 1, 1]
var balance: Array[int] = [0, 0, 0]

# upgrades
var damage := 1.0
var fire_rate := 1.0

var invulnerability_time := 1.0

var move_speed := 500.0
var rotation_speed := 4.0

# player state
var player_max_health := 10
var player_health := 10

var levels_complete :int = 6

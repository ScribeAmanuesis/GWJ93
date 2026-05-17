extends Control

@onready var damage_label: Label = $RedItems/Damage/NinePatchRect2/Label
@onready var firerate_label: Label = $RedItems/Firerate/NinePatchRect2/Label

@onready var invunerability_label: Label = $BlueItems/Invulnerability/NinePatchRect2/Label

@onready var rotation_spd_label: Label = $GreenItems/RotationSpeed/NinePatchRect2/Label
@onready var move_spd_label: Label = $GreenItems/MoveSpeed/NinePatchRect2/Label

var firerate_price := 4
var damage_price := 6

var invulnerability_price := 2
var heal_price := 1

var move_speed_price := 6
var rotation_speed_price := 4


var firerate_left := 3
var damage_left := 3
var invulnerability_left := 3
var move_speed_left := 3
var rotation_speed_left := 3

@onready var balance: HBoxContainer = $Balance


func _ready() -> void:
	update_labels()


func update_labels() -> void:
	damage_label.text = "Ship's laser deals more damage (%d left)" % damage_left
	firerate_label.text = "Ship shoots faster (%d left)" % firerate_left
	invunerability_label.text = "Longer invincibility after receiving damage (%d left)" % invulnerability_left
	rotation_spd_label.text = "Ship rotates faster\n(%d left)" % rotation_speed_left
	move_spd_label.text = "Ship flies faster (%d left)" % move_speed_left


func buy_item(balance_index: int, price: int) -> bool:
	if Global.balance[balance_index] >= price:
		Global.balance[balance_index] -= price
		return true

	return false


func _on_back_shop_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/mission_screen.tscn")


func _on_firerate_buy_button_up() -> void:
	if firerate_left <= 0:
		return

	if buy_item(0, firerate_price):
		Global.fire_rate += 0.1
		firerate_left -= 1
		balance.fill_balance()
		update_labels()


func _on_damage_buy_button_up() -> void:
	if damage_left <= 0:
		return

	if buy_item(0, damage_price):
		Global.damage += 1
		damage_left -= 1
		balance.fill_balance()
		update_labels()


func _on_invunerability_buy_button_up() -> void:
	if invulnerability_left <= 0:
		return

	if buy_item(1, invulnerability_price):
		Global.invulnerability_time += 0.5
		invulnerability_left -= 1
		balance.fill_balance()
		update_labels()


func _on_heal_buy_button_up() -> void:
	if buy_item(1, heal_price):
		Global.player_health = Global.player_max_health
		balance.fill_balance()


func _on_move_spd_buy_button_up() -> void:
	if move_speed_left <= 0:
		return

	if buy_item(2, move_speed_price):
		Global.move_speed += 25
		move_speed_left -= 1
		balance.fill_balance()
		update_labels()


func _on_rotation_spd_buy_button_up() -> void:
	if rotation_speed_left <= 0:
		return
	if buy_item(2, rotation_speed_price):
		Global.rotation_speed += 0.2
		rotation_speed_left -= 1
		balance.fill_balance()
		update_labels()

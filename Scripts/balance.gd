extends HBoxContainer
@onready var red_balance: Label = $RedBalance
@onready var blue_balance: Label = $BlueBalance
@onready var green_balance: Label = $GreenBalance


func fill_balance():
	red_balance.text = str(Global.balance[0])
	blue_balance.text = str(Global.balance[1])
	green_balance.text = str(Global.balance[2])
func _ready() -> void:
	fill_balance()

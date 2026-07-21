extends Control

@onready var currency = $VBoxContainer/Currency
@onready var day = $VBoxContainer/Day
@onready var playtime = $VBoxContainer/Playtime

func _ready():
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)
	day.text = "Current Day: " + str(Global.current_day)
	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)
	
	Global.day_passed.connect(update_display)
	GlobalCombatInformation.check_quest_progress.connect(update_display)
	GlobalCombatInformation.did_something_with_money.connect(update_display)
	GlobalCombatInformation.did_something_with_BP.connect(update_display)
	
func update_display(old_money_count = 0, currency_change = 0):
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)

	day.text = "Current Day: " + str(Global.current_day)
	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)

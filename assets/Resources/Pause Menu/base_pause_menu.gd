extends Control

@onready var currency = $VBoxContainer/Currency
@onready var cur_bp = $VBoxContainer/BP
@onready var day = $VBoxContainer/Day
@onready var playtime = $VBoxContainer/Playtime

func _ready():
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)
	cur_bp.text = "BP: " + str(GlobalCombatInformation.current_BP) + "/" + str(GlobalCombatInformation.max_BP)
	
	day.text = "Current Day: " + str(Global.current_day)
	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)
	
	Global.day_passed.connect(update_display)
	GlobalCombatInformation.check_quest_progress.connect(update_display)
	GlobalCombatInformation.did_something_with_money.connect(update_display)
	GlobalCombatInformation.did_something_with_BP.connect(update_display)
	
func update_display():
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)
	cur_bp.text = "BP: " + str(GlobalCombatInformation.current_BP) + "/" + str(GlobalCombatInformation.max_BP)
	
	day.text = "Current Day: " + str(Global.current_day)
	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)

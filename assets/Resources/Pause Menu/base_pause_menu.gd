extends Control

@onready var currency = $VBoxContainer/Container/HBoxContainer/Currency
@onready var playtime = $VBoxContainer/Playtime
@onready var resonate = $VBoxContainer/Container2/HBoxContainer/Resonate

func _ready():
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)
	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)
	resonate.text = "Resonated with: " + GlobalCombatInformation.resonated_name
	
	if GlobalCombatInformation.resonated_name == "" or GlobalCombatInformation.resonated_name == "Base":
		resonate.text = "Resonated with: No One"
	
	StateManager.state_set.connect(update_display)
	
	Global.day_passed.connect(update_display)
	GlobalCombatInformation.check_quest_progress.connect(update_display)
	GlobalCombatInformation.did_something_with_money.connect(update_display)
	GlobalCombatInformation.did_something_with_BP.connect(update_display)
	GlobalCombatInformation.update_resonance.connect(update_display)
	
func update_display(old_money_count = 0, currency_change = 0):
	currency.text = "Money: " + str(GlobalCombatInformation.currency_held)

	playtime.text = "Play Time: " + str(Global.play_time_hours) + ":" + str(Global.play_time_minutes)
	resonate.text = "Resonated with: " + GlobalCombatInformation.resonated_name
	
	if StateManager.check_completion(StateManager.story_beats_lookup.FIRST_SEAL_DUNGEON_BEATEN, StateManager.completion_checks.STORY_CHECKS):
		$HBoxContainer/Panel.visible = true
	else:
		$HBoxContainer/Panel.visible = false
	
	if GlobalCombatInformation.resonated_name == "" or GlobalCombatInformation.resonated_name == "Base":
		resonate.text = "Resonated with: No One"

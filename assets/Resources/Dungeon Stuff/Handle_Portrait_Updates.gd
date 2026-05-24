extends Control

class_name player_portraits

@onready var health_bar = $HealthBar
@onready var health_num = $Health_Num
@onready var party_portrait = $Portrait
@onready var portrait_name = $Name
@onready var portrait_status = $Statuses
@onready var stat_changes = $Stat_Changes

func _setup(person_to_setup: generic_combatants):
	health_bar.max_value = person_to_setup.combatant_stats.max_health
	health_bar.value = person_to_setup.combatant_stats.health
	health_num.text = str(int(health_bar.value)) + " / " + str(int(health_bar.max_value))
	party_portrait.texture = person_to_setup.party_member_portrait
	portrait_name.text = person_to_setup.combatant_name
	
func _update_health(health_value):
	health_bar.value -= floor(health_value)
	health_num.text = str(int(health_bar.value))

func update_statuses(person_to_do_it_for: combat_template):
	reset_ui()
	for status_ in person_to_do_it_for.active_statuses:
		match status_.status_name:
			"Stun":
				print("STUN")
				portrait_status.get_child(0).visible = true
			"Sleep":
				print("SLEEP")
				portrait_status.get_child(1).visible = true
			"Shock":
				print("SHOCK")
				portrait_status.get_child(2).visible = true
			"Poison":
				print("POISON")
				portrait_status.get_child(3).visible = true
			"Freeze":
				print("FREEZE")
				portrait_status.get_child(4).visible = true
			"Burn":
				print("BURN")
				portrait_status.get_child(5).visible = true
		if status_.status_name.find("-") != -1:
			manage_stat_stuff(false, status_.status_name.split("-"))
		elif status_.status_name.find("+") != -1:
			manage_stat_stuff(true, status_.status_name.split("+"))
	
func manage_stat_stuff(stat_up_or_down, status_to_track):
	match status_to_track[0]:
		"Attack":
			if stat_up_or_down:
				stat_changes.get_child(0).get_child(0).get_child(0).visible = true
			else:
				stat_changes.get_child(0).get_child(1).visible = true
		"Defense":
			if stat_up_or_down:
				stat_changes.get_child(1).get_child(0).get_child(0).visible = true
			else:
				stat_changes.get_child(1).get_child(1).visible = true
		"Evasion":
			if stat_up_or_down:
				stat_changes.get_child(2).get_child(0).get_child(0).visible = true
			else:
				stat_changes.get_child(2).get_child(1).visible = true
		"CritChance":
			if stat_up_or_down:
				stat_changes.get_child(3).get_child(0).get_child(0).visible = true
			else:
				stat_changes.get_child(3).get_child(1).visible = true
		"Accuracy":
			if stat_up_or_down:
				stat_changes.get_child(4).get_child(0).get_child(0).visible = true
			else:
				stat_changes.get_child(4).get_child(1).visible = true

func reset_ui():
	for status_ in portrait_status.get_children():
		status_.visible = false
	for stat_change in stat_changes.get_children():
		stat_change.get_child(0).get_child(0).visible = false
		stat_change.get_child(1).visible = false

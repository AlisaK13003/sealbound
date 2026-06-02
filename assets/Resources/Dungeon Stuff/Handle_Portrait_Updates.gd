extends Control

class_name player_portraits

@onready var health_bar = $HealthBar
@onready var health_num = $Health_Num
@onready var party_portrait = $Portrait
@onready var portrait_name = $Name
@onready var portrait_status = $Statuses

func _setup(person_to_setup: generic_combatants):
	health_bar.max_value = person_to_setup.combatant_stats.max_health
	health_bar.value = person_to_setup.combatant_stats.health
	health_num.text = str(int(health_bar.value))
	party_portrait.texture = person_to_setup.party_member_portrait
	portrait_name.text = person_to_setup.combatant_name
	
func _update_health(health_value):
	if health_value is Array:
		health_bar.value = clamp(floor(health_bar.value - health_value[0]), 0, health_bar.max_value)
		health_num.text = str(int(health_bar.value))
	else:
		health_bar.value = clamp(floor(health_bar.value - health_value), 0, health_bar.max_value)
		health_num.text = str(int(health_bar.value))

func update_statuses(person_to_do_it_for: combat_template):
	reset_ui()
	for status_ in person_to_do_it_for.active_statuses:
		match status_.status_name:
			"Stun":

				portrait_status.get_child(0).visible = true
			"Sleep":

				portrait_status.get_child(1).visible = true
			"Shock":

				portrait_status.get_child(2).visible = true
			"Poison":
				portrait_status.get_child(3).visible = true
			"Freeze":

				portrait_status.get_child(4).visible = true
			"Burn":

				portrait_status.get_child(5).visible = true

	


func reset_ui():
	for status_ in portrait_status.get_children():
		status_.visible = false

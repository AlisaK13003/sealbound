extends Control

func _setup(combatant: generic_combatants):
	$VBoxContainer/GridContainer3/Level.text = "Level: " + str(combatant.combatant_stats.level)
	$GridContainer2/HBoxContainer/Health2.text = str(combatant.combatant_stats.health)
	$GridContainer2/HBoxContainer2/Attack2.text = str(combatant.combatant_stats.attack)
	$GridContainer2/HBoxContainer3/Defense2.text = str(combatant.combatant_stats.defense)
	$GridContainer2/HBoxContainer4/Magic2.text = str(combatant.combatant_stats.magic)
	$GridContainer2/HBoxContainer5/Resistance2.text = str(combatant.combatant_stats.resistance)
	$GridContainer2/HBoxContainer6/Speed2.text = str(combatant.combatant_stats.speed)
	$GridContainer2/HBoxContainer7/Luck2.text = str(combatant.combatant_stats.luck)
	$GridContainer2/HBoxContainer8/Evasion2.text = str(combatant.combatant_stats.evasion)
	
	$"VBoxContainer/GridContainer3/Total Exp".text = "EXP: " + str(combatant.total_experience_points)
	$"VBoxContainer/GridContainer3/Exp to next level".text = "next level: " + str(combatant.add_experience(0))
	
	$"VBoxContainer/GridContainer/Current Equipment".text = "Current Equipment: " + combatant.stored_equipment.equipment_name
	$"VBoxContainer/GridContainer/Current Weapon".text = "Current Weapon: " + combatant.stored_weapon.weapon_name
	

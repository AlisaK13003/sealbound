extends Control

var stored_combatant = null

func _ready():
	GlobalCombatInformation.check_player_values.connect(_setup)

func _setup(combatant: generic_combatants = null):
	if combatant == null:
		combatant = stored_combatant
	$VBoxContainer/GridContainer3/Level.text = "Level: " + str(combatant.actual_stats.level)
	$GridContainer2/HBoxContainer/Health2.text = str(combatant.actual_stats.health)
	$GridContainer2/HBoxContainer2/Attack2.text = str(combatant.actual_stats.attack)
	$GridContainer2/HBoxContainer3/Defense2.text = str(combatant.actual_stats.defense)
	$GridContainer2/HBoxContainer4/Magic2.text = str(combatant.actual_stats.magic)
	$GridContainer2/HBoxContainer5/Resistance2.text = str(combatant.actual_stats.resistance)
	$GridContainer2/HBoxContainer6/Speed2.text = str(combatant.actual_stats.speed)
	$GridContainer2/HBoxContainer7/Luck2.text = str(combatant.actual_stats.luck)
	$GridContainer2/HBoxContainer8/Evasion2.text = str(combatant.actual_stats.evasion)
	
	$"VBoxContainer/GridContainer3/Total Exp".text = "EXP: " + str(combatant.total_experience_points)
	$"VBoxContainer/GridContainer3/Exp to next level".text = "next level: " + str(combatant.add_experience(0))
	
	$GridContainer/TextureRect.texture = combatant.stored_equipment.equipment_sprite
	$GridContainer/TextureRect2.texture = combatant.stored_weapon.weapon_texture
	$GridContainer/TextureRect3.texture = combatant.stored_chestplate.equipment_sprite
	$GridContainer/TextureRect4.texture = combatant.stored_boots.equipment_sprite
	$GridContainer/TextureRect5.texture = combatant.stored_charm.equipment_sprite
	
	$AnimatedSprite2D/Label.text = combatant.combatant_name
	$AnimatedSprite2D.sprite_frames = combatant.sprite_frames
	$AnimatedSprite2D.play("Idle")
	$AnimatedSprite2D.offset = combatant.equip_sprite_offset
	$EXP_bar.max_value = ceili((100 * pow(1.2, combatant.combatant_stats.level)) - 120) - (combatant.total_experience_points - ceili((100 * pow(1.2, combatant.combatant_stats.level)) - 120))
	$EXP_bar.value = $EXP_bar.max_value - combatant.add_experience(0) 

	if combatant.is_MC:
		$Label/CheckBox.disabled = true
		$Label/CheckBox.button_pressed = true
	else:
		if GlobalCombatInformation.check_if_member_is_active(combatant):
			$Label/CheckBox.button_pressed = true
		$Label/CheckBox.disabled = false
		
	stored_combatant = combatant
	if GlobalCombatInformation.in_dungeon:
		$Label/CheckBox.disabled = true
	

func _on_check_box_toggled(toggled_on):
	if toggled_on:
		GlobalCombatInformation.add_active_member(stored_combatant)
	else:
		GlobalCombatInformation.remove_active_member(stored_combatant)

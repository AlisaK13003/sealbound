extends Control

var stored_combatant: generic_combatants = null

func _ready():
	GlobalCombatInformation.check_player_values.connect(_setup)
	GlobalCombatInformation.update_resonance.connect(update_resonance)
	$GenericButton.activated.connect(_on_member_resonated)
	
func update_resonance():
	if stored_combatant.resonated_with:
		$Label2/CheckBox.button_pressed = true
	else:
		$Label2/CheckBox.button_pressed = false

func _setup(combatant: generic_combatants = null):
	if combatant == null:
		combatant = stored_combatant
	stored_combatant = combatant
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
	
	$GridContainer/TextureRect2.texture = combatant.stored_equipment.equipment_sprite if combatant.stored_equipment != null else null
	$GridContainer/TextureRect.texture = combatant.stored_weapon.weapon_texture if combatant.stored_weapon != null else null
	$GridContainer/TextureRect3.texture = combatant.stored_chestplate.equipment_sprite if combatant.stored_chestplate != null else null
	$GridContainer/TextureRect4.texture = combatant.stored_boots.equipment_sprite if combatant.stored_boots != null else null
	$GridContainer/TextureRect5.texture = combatant.stored_charm.equipment_sprite if combatant.stored_charm != null else null
	
	$AnimatedSprite2D/Label.text = combatant.combatant_name
	$AnimatedSprite2D.sprite_frames = combatant.sprite_frames
	$AnimatedSprite2D.play("Idle")
	$AnimatedSprite2D.offset = combatant.equip_sprite_offset

	update_exp_bar(stored_combatant)

	if combatant.is_MC:
		$Label/CheckBox.disabled = true
		$Label/CheckBox.button_pressed = true
		$Label2/CheckBox.disabled = true
	else:
		if GlobalCombatInformation.check_if_member_is_active(combatant):
			$Label/CheckBox.button_pressed = true
		$Label/CheckBox.disabled = false
	

	if GlobalCombatInformation.in_dungeon:
		$Label/CheckBox.disabled = true
	
	if stored_combatant.resonated_with:
		$Label2/CheckBox.button_pressed = true
	else:
		$Label2/CheckBox.button_pressed = false

func update_exp_bar(combatant):	
	var current_level_req = combatant.get_level_threshold(stored_combatant.combatant_stats.level - 1)   
	var next_level_req = combatant.get_level_threshold(stored_combatant.combatant_stats.level)  
	
	$EXP_bar.min_value = current_level_req
	$EXP_bar.max_value = next_level_req
	$EXP_bar.value = combatant.total_experience_points

func _on_check_box_toggled(toggled_on):
	if toggled_on:
		GlobalCombatInformation.add_active_member(stored_combatant)
	else:
		GlobalCombatInformation.remove_active_member(stored_combatant)

func _on_member_resonated():
	if stored_combatant.is_MC:
		return
	if $Label2/CheckBox.button_pressed:
		GlobalCombatInformation.resonate_with_a_member(stored_combatant, false)
		$Label2/CheckBox.button_pressed = false
	else:
		GlobalCombatInformation.resonate_with_a_member(stored_combatant, true)
		$Label2/CheckBox.button_pressed = true

extends Control

signal equip_slot_pressed

var weapon_info
var chestplate_info
var boot_info
var helmet_info
var charm_info

var stored_combatant: generic_combatants

var weapon_slot
var helmet_slot
var boots_slot
var charm_slot
var chestplate_slot

func _setup(combatant: generic_combatants):
	weapon_info = combatant.stored_weapon.return_stuff()
	chestplate_info = combatant.stored_chestplate.return_stuff()
	boot_info = combatant.stored_boots.return_stuff()
	helmet_info = combatant.stored_equipment.return_stuff()
	charm_info = combatant.stored_charm.return_stuff()
	
	stored_combatant = combatant
	
	$GridContainer/Panel2/Helmet.text = helmet_info["name"] + ": \n     " + combatant.stored_equipment.get_stat_string()
	$GridContainer/Panel3/Weapon.text = weapon_info["name"] + ": \n     " + combatant.stored_weapon.get_stat_string()
	$GridContainer/Panel5/Boots.text = boot_info["name"] + ": \n     " + combatant.stored_boots.get_stat_string()
	$GridContainer/Panel4/Chestplate.text = chestplate_info["name"] + ": \n     " + combatant.stored_chestplate.get_stat_string()
	$GridContainer/Panel6/Charm.text = charm_info["name"] + ": \n     " + combatant.stored_charm.get_stat_string()
	
	$GridContainer3/HBoxContainer/Health2.text = str(combatant.actual_stats.health)
	$GridContainer3/HBoxContainer2/Attack2.text = str(combatant.actual_stats.attack)
	$GridContainer3/HBoxContainer3/Defense2.text = str(combatant.actual_stats.defense)
	$GridContainer3/HBoxContainer4/Magic2.text = str(combatant.actual_stats.magic)
	$GridContainer3/HBoxContainer5/Resistance2.text = str(combatant.actual_stats.resistance)
	$GridContainer3/HBoxContainer6/Speed2.text = str(combatant.actual_stats.speed)
	$GridContainer3/HBoxContainer7/Luck2.text = str(combatant.actual_stats.luck)
	$GridContainer3/HBoxContainer8/Evasion2.text = str(combatant.actual_stats.evasion)
	
	$GridContainer3/HBoxContainer/Health3.text = str(combatant.actual_stats.health)
	$GridContainer3/HBoxContainer2/Attack3.text = str(combatant.actual_stats.attack)
	$GridContainer3/HBoxContainer3/Defense3.text = str(combatant.actual_stats.defense)
	$GridContainer3/HBoxContainer4/Magic3.text = str(combatant.actual_stats.magic)
	$GridContainer3/HBoxContainer5/Resistance3.text = str(combatant.actual_stats.resistance)
	$GridContainer3/HBoxContainer6/Speed3.text = str(combatant.actual_stats.speed)
	$GridContainer3/HBoxContainer7/Luck3.text = str(combatant.actual_stats.luck)
	$GridContainer3/HBoxContainer8/Evasion3.text = str(combatant.actual_stats.evasion)
	
	weapon_slot = $GridContainer2/Weapon_Slot
	helmet_slot = $GridContainer2/Helmet_Slot
	boots_slot = $GridContainer2/Boots_Slot
	charm_slot = $GridContainer2/Charm_Slot
	chestplate_slot = $GridContainer2/Chestplat_Slot
	
	weapon_slot.get_child(0).texture = weapon_info["texture"]
	chestplate_slot.get_child(0).texture = chestplate_info["texture"]
	boots_slot.get_child(0).texture = boot_info["texture"]
	helmet_slot.get_child(0).texture = helmet_info["texture"]
	charm_slot.get_child(0).texture = charm_info["texture"]

	weapon_slot.gui_input.connect(_on_equip_slot_gui_input.bind(0))
	chestplate_slot.gui_input.connect(_on_equip_slot_gui_input.bind(4))
	boots_slot.gui_input.connect(_on_equip_slot_gui_input.bind(2))
	helmet_slot.gui_input.connect(_on_equip_slot_gui_input.bind(1))
	charm_slot.gui_input.connect(_on_equip_slot_gui_input.bind(3))
	
	var party_member_sprite: AnimatedSprite2D = $AnimatedSprite2D
	party_member_sprite.sprite_frames = combatant.sprite_frames
	party_member_sprite.play("Idle")
	party_member_sprite.offset = combatant.equip_sprite_offset
	
	GlobalCombatInformation.equipment_added.connect(update_stuff)

func update_stuff():
	update_boxes(stored_combatant.stored_weapon, true)
	update_boxes(stored_combatant.stored_equipment, false)
	update_boxes(stored_combatant.stored_boots, false)
	update_boxes(stored_combatant.stored_charm, false)
	update_boxes(stored_combatant.stored_chestplate, false)
	
	$GridContainer3/HBoxContainer/Health2.text = str(stored_combatant.actual_stats.health)
	$GridContainer3/HBoxContainer2/Attack2.text = str(stored_combatant.actual_stats.attack)
	$GridContainer3/HBoxContainer3/Defense2.text = str(stored_combatant.actual_stats.defense)
	$GridContainer3/HBoxContainer4/Magic2.text = str(stored_combatant.actual_stats.magic)
	$GridContainer3/HBoxContainer5/Resistance2.text = str(stored_combatant.actual_stats.resistance)
	$GridContainer3/HBoxContainer6/Speed2.text = str(stored_combatant.actual_stats.speed)
	$GridContainer3/HBoxContainer7/Luck2.text = str(stored_combatant.actual_stats.luck)
	$GridContainer3/HBoxContainer8/Evasion2.text = str(stored_combatant.actual_stats.evasion)
	
func update_boxes(equip, is_weapon):
	if is_weapon:
		weapon_info = stored_combatant.stored_weapon.return_stuff()
		$GridContainer/Panel3/Weapon.text = weapon_info["name"] + ": \n     " + stored_combatant.stored_weapon.get_stat_string()
		weapon_slot.get_child(0).texture = weapon_info["texture"]
	else:
		match equip.equipment_type:
			0:
				helmet_info = stored_combatant.stored_equipment.return_stuff()
				$GridContainer/Panel2/Helmet.text = helmet_info["name"] + ": \n     " + stored_combatant.stored_equipment.get_stat_string()
				helmet_slot.get_child(0).texture = helmet_info["texture"]
			1:
				chestplate_info = stored_combatant.stored_chestplate.return_stuff()
				$GridContainer/Panel4/Chestplate.text = chestplate_info["name"] + ": \n     " + stored_combatant.stored_chestplate.get_stat_string()
				chestplate_slot.get_child(0).texture = chestplate_info["texture"]
			2:
				boot_info = stored_combatant.stored_boots.return_stuff()
				$GridContainer/Panel5/Boots.text = boot_info["name"] + ": \n     " + stored_combatant.stored_boots.get_stat_string()
				boots_slot.get_child(0).texture = boot_info["texture"]
			3:
				charm_info = stored_combatant.stored_charm.return_stuff()
				$GridContainer/Panel6/Charm.text = charm_info["name"] + ": \n     " + stored_combatant.stored_charm.get_stat_string()
				charm_slot.get_child(0).texture = charm_info["texture"]

func update_prediction_stats(selected_equipment, is_weapon):
	if selected_equipment == null:
		for child in $GridContainer3.get_children():
			if int(child.get_child(3).text) > int(child.get_child(1).text):
				child.get_child(3).add_theme_color_override("font_color", Color.GREEN)
			elif int(child.get_child(3).text) == int(child.get_child(1).text):
				child.get_child(3).add_theme_color_override("font_color", Color.WHITE)
			else:
				child.get_child(3).add_theme_color_override("font_color", Color.RED)
		return
	var temp_combatant = stored_combatant.duplicate()
	if selected_equipment is equipment:
		match selected_equipment.equipment_type:
			0:
				temp_combatant.stored_equipment = selected_equipment
			1:
				temp_combatant.stored_chestplate = selected_equipment
			2:
				temp_combatant.stored_boots = selected_equipment
			3:
				temp_combatant.stored_charm = selected_equipment
	else:
		temp_combatant.stored_weapon = selected_equipment
	temp_combatant.gather_actual_stats()
	
	$GridContainer3/HBoxContainer/Health3.text = str(temp_combatant.actual_stats.health)
	$GridContainer3/HBoxContainer2/Attack3.text = str(temp_combatant.actual_stats.attack)
	$GridContainer3/HBoxContainer3/Defense3.text = str(temp_combatant.actual_stats.defense)
	$GridContainer3/HBoxContainer4/Magic3.text = str(temp_combatant.actual_stats.magic)
	$GridContainer3/HBoxContainer5/Resistance3.text = str(temp_combatant.actual_stats.resistance)
	$GridContainer3/HBoxContainer6/Speed3.text = str(temp_combatant.actual_stats.speed)
	$GridContainer3/HBoxContainer7/Luck3.text = str(temp_combatant.actual_stats.luck)
	$GridContainer3/HBoxContainer8/Evasion3.text = str(temp_combatant.actual_stats.evasion)

	for child in $GridContainer3.get_children():
		if int(child.get_child(3).text) > int(child.get_child(1).text):
			child.get_child(3).add_theme_color_override("font_color", Color.GREEN)
		elif int(child.get_child(3).text) == int(child.get_child(1).text):
			child.get_child(3).add_theme_color_override("font_color", Color.WHITE)
		else:
			child.get_child(3).add_theme_color_override("font_color", Color.RED)
	

func _on_equip_slot_gui_input(event, extra_arg_0):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Clicked on slot, ", extra_arg_0)
			equip_slot_pressed.emit(extra_arg_0)

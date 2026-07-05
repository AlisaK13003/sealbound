extends Control

signal equip_slot_pressed

var weapon_info
var chestplate_info
var boot_info
var helmet_info
var charm_info

var stored_combatant

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
	
	weapon_slot = $Weapon_Slot
	helmet_slot = $Helmet_Slot
	boots_slot = $Boots_Slot
	charm_slot = $Charm_Slot
	chestplate_slot = $Chestplat_Slot
	
	weapon_slot.get_child(0).texture = weapon_info["texture"]
	chestplate_slot.get_child(0).texture = chestplate_info["texture"]
	boots_slot.get_child(0).texture = boot_info["texture"]
	helmet_slot.get_child(0).texture = helmet_info["texture"]
	charm_slot.get_child(0).texture = charm_info["texture"]

	var party_member_sprite: AnimatedSprite2D = $AnimatedSprite2D
	party_member_sprite.sprite_frames = combatant.sprite_frames
	party_member_sprite.play("Idle")
	party_member_sprite.offset = combatant.equip_sprite_offset
	
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

func _on_equip_slot_gui_input(event, extra_arg_0):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Clicked on slot, ", extra_arg_0)
			equip_slot_pressed.emit(extra_arg_0)

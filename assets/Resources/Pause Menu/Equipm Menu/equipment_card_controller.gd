extends Control

func _setup(combatant: generic_combatants):
	var weapon_info = combatant.stored_weapon.return_stuff()
	var chestplate_info = combatant.stored_chestplate.return_stuff()
	var boot_info = combatant.stored_boots.return_stuff()
	var helmet_into = combatant.stored_equipment.return_stuff()
	var charm_info = combatant.stored_charm.return_stuff()
	
	# Each will return
	#var dict = {
	#	"name"
	#	"description"
	#	"texture"
	#	"attack"
	#	"defense"
	#	"magic"
	#	"resistance"
	#	"crit chance"
	#	"crit damage"
	#	"speed"
	#	"evasion"
	#	"luck"
	#}
	
	$VBoxContainer/Helmet.text = helmet_into["name"] + ": \n     " + str(helmet_into["health"]) + " Health, " + str(helmet_into["resistance"]) + " Resistance"
	$VBoxContainer/Weapon.text = weapon_info["name"] + ": \n     " + str(weapon_info["attack"]) + " Attack, " + str(weapon_info["crit chance"]) + " Crit Chance, " + str(weapon_info["crit damage"]) + " Crit Damage"
	$VBoxContainer/Boots.text = boot_info["name"] + ": \n     " + str(boot_info["speed"]) + " Speed, " + str(boot_info["evasion"]) + " Evasion"
	$VBoxContainer/Chestplate.text = chestplate_info["name"] + ": \n     " + str(chestplate_info["health"]) + " Health, " + str(chestplate_info["defense"]) + " Defense"
	$VBoxContainer/Charm.text = charm_info["name"] + ": \n     " + str(charm_info["magic"]) + " Magic, " + str(charm_info["luck"]) + " Luck"
	
	
	var weapon_slot = $Weapon_Slot
	var helmet_slot = $Helmet_Slot
	var boots_slot = $Boots_Slot
	var charm_slot = $Charm_Slot
	var chestplate_slot = $Chestplat_Slot
	
	weapon_slot.get_child(0).texture = weapon_info["texture"]
	chestplate_slot.get_child(0).texture = chestplate_info["texture"]
	boots_slot.get_child(0).texture = boot_info["texture"]
	helmet_slot.get_child(0).texture = helmet_into["texture"]
	charm_slot.get_child(0).texture = charm_info["texture"]

	var party_member_sprite = $AnimatedSprite2D
	party_member_sprite.sprite_frames = combatant.sprite_frames
	party_member_sprite.play("Idle")
	
	
	

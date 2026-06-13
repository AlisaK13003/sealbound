extends Control

@onready var weapon_sprite = $Weapon_Sprite
@onready var equipment_sprite = $Equipment_Sprite
@onready var weapon_name = $Weapon/Weapon_Name
@onready var equipment_name = $Equipment/Equipment_Name
@onready var attack_power = $Weapon/HBoxContainer/Attack_pwr
@onready var attack_acc = $Weapon/HBoxContainer/Attack_acc
@onready var equip_def = $Equipment/HBoxContainer/Equip_def
@onready var equip_eva = $Equipment/HBoxContainer/Equip_eva

func setup(node_to_setup: generic_combatants):
	var onboarding_weapon : weapon = node_to_setup.stored_weapon
	var onboarding_equipment : equipment= node_to_setup.stored_equipment
	weapon_name.text = onboarding_weapon.weapon_name
	equipment_name.text = onboarding_equipment.equipment_name
	attack_power.text = "Attack: " + str(onboarding_weapon.weapon_attack)
	attack_acc.text = "Accuracy: " + str(onboarding_weapon.attack_accuracy)
	equip_def.text = "Defense: " + str(onboarding_equipment.equipment_stats.defense)
	equip_eva.text = "Evasion: " + str(onboarding_equipment.equipment_stats.evasion)

extends Control

class_name combatant_ui

@onready var base_menu = $Player_Menu/Base_Menu
@onready var action_menu = $Player_Menu/Action_Menu
@onready var skill_menu = $Player_Menu/Skill_Menu
@onready var item_menu = $Player_Menu/Item_Menu

@onready var health_bar = $TextureProgressBar

var parent_reference

func _ready():
	reset_ui()

func setup(parent_ref, party_member: generic_combatants):
	parent_reference = parent_ref
	
	for move in range(party_member.combatant_skills.size()):
		if party_member.combatant_skills[move] == null:
			continue
		var skill_node: TextureButton = skill_menu.get_child(move + 1)
		if not party_member.combatant_skills[move].is_unlocked:
			skill_node.visible = false
		else:
			for mana in range(party_member.combatant_skills[move].mana_cost):
				skill_node.get_child(mana).visible = true

		skill_node.texture_normal = party_member.combatant_skills[move].normal_sprite
		skill_node.texture_pressed = party_member.combatant_skills[move].pressed_sprite
		#skill_node.texture_hover = party_member.combatant_skills[move].hover_sprite
		skill_node.texture_disabled = party_member.combatant_skills[move].disabled_sprite

		
func reset_ui():
	un_toggle_all_buttons()
	base_menu.visible = true
	action_menu.visible = false
	skill_menu.visible = false
	item_menu.visible = false

func handle_menu_swapping(swap_to_what_menu: int):
	if not parent_reference.parent_reference.selected_item.visible:
		reset_ui()
	match swap_to_what_menu:
		# Back button pressed
		0:
			if parent_reference.parent_reference.selected_item.visible:
				parent_reference.parent_reference.selected_item.visible = false
				parent_reference.parent_reference.item_menu.visible = true
				parent_reference.parent_reference.unhighlight_all_entities()
				parent_reference.parent_reference.actual_confirmation.emit("NOPE")
				return
			elif parent_reference.parent_reference.item_menu:
				parent_reference.parent_reference.item_menu.visible = false
			parent_reference.parent_reference.confirmation.emit(false)
			parent_reference.parent_reference.unhighlight_all_entities()
		# Swap to Action Menu
		1:
			base_menu.visible = false
			action_menu.visible = true
		# Swap to Skill Menu
		2:
			base_menu.visible = false
			skill_menu.visible = true
		# Swap to Item Menu
		3:
			base_menu.visible = false
			item_menu.visible = true
			parent_reference.parent_reference.item_menu.visible = true
			
func use_skill(what_skill):
	var target_button = skill_menu.get_child(what_skill + 1)
	
	if target_button.button_pressed:
		for i in [1, 2, 3]:
			if i != (what_skill + 1):
				skill_menu.get_child(i).button_pressed = false
				
		parent_reference.parent_reference.unhighlight_all_entities()
		parent_reference.parent_reference.skill_selected(what_skill, parent_reference.child_number)
	else:
		if parent_reference.stored_combatant.combatant_skills[what_skill].is_skill_aoe:
			return
		parent_reference.parent_reference.unhighlight_all_entities()
		parent_reference.parent_reference.revert_to_default_UI()

func update_skill_buttons(player_to_check: generic_combatants, total_mana):
	for move in range(player_to_check.combatant_skills.size()):
		var skill_node: TextureButton = skill_menu.get_child(move + 1)
		if player_to_check.combatant_skills[move] == null:
			continue
		
		if total_mana >= player_to_check.combatant_skills[move].mana_cost:
			skill_node.disabled = false
		else:
			skill_node.disabled = true

func base_attack_defend_selected(attack_or_defend):
	if attack_or_defend:
		parent_reference.parent_reference.attack_button_pressed(parent_reference.child_number)
	else:
		if action_menu.get_child(1).pressed:
			parent_reference.parent_reference.unhighlight_all_entities()
		parent_reference.parent_reference.defend_button_pressed(parent_reference, parent_reference.child_number)

func _on_texture_button_button_down():
	if parent_reference.currently_selectable:
		parent_reference.parent_reference.confirmation.emit(parent_reference.child_number)

func un_toggle_all_buttons():
	for menu in $Player_Menu.get_children():
		for button in menu.get_children():
			button.button_pressed = false

func _mouse_hovered_over_skill(extra_arg_0):
	$Player_Menu/Skill_Menu/Back_Button/Description.text = parent_reference.stored_combatant.combatant_skills[extra_arg_0].move_description

func _mouse_left_skill(extra_arg_0):
	$Player_Menu/Skill_Menu/Back_Button/Description.text = ""

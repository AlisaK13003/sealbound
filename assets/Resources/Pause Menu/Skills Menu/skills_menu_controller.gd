extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs

@onready var skill_card_container = $Control

var active_skill_instance_id: int = -1

var _is_snapping_back: bool = false

var caster_index: int = 0
var trying_to_use_skill: bool = false
var skill_used: moves

func _ready():
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child, true)
		var new_skill_card = load("res://assets/Resources/Pause Menu/Skills Menu/party_skill_card.tscn")
		var card_instance = new_skill_card.instantiate()
		card_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		skill_card_container.add_child(card_instance)
		if card_instance.get_index() != 0:
			card_instance.visible = false
			
	menu_tabs.selection_changed.connect(_tab_changed)
	
	for card in $Control.get_children():
		for move_card in card.move_container.get_children():
			move_card.skill_clicked.connect(update_skill_description)
			
	visibility_changed.connect(_on_visibility_changed)
	
	_on_visibility_changed()
	
func _on_visibility_changed() -> void:
	if visible:
		active_skill_instance_id = -1
		trying_to_use_skill = false
		skill_used = null
		$Panel/Label.text = "Use"
		for child in menu_tabs.get_children():
			_set_node_mouse_disabled(child, false)
			
		if menu_tabs.has_method("cycle_input"):
			menu_tabs.cycle_input(null, -1000) 
			menu_tabs.cycle_input(null, 0)     
		
		_tab_changed(0)
	else:
		trying_to_use_skill = false
		skill_used = null
		$Panel/Label.text = "Use"
		for child in menu_tabs.get_children():
			_set_node_mouse_disabled(child, false)
			
		if menu_tabs.has_method("cycle_input"):
			menu_tabs.cycle_input(null, -1000)

func _tab_changed(tab):
	if _is_snapping_back:
		return
		
	if trying_to_use_skill:
		if skill_used.targets_self:
			if tab != caster_index:
				_reject_cast_and_restore_visuals()
				return
				
			var target_member = GlobalCombatInformation.all_party_slots[caster_index]
			if target_member.actual_stats.health >= target_member.actual_stats.max_health:
				print("User has full health!")
				_reject_cast_and_restore_visuals()
				return
			
			var heal_amount = 0
			if skill_used.get_skill_boost() != 999:
				heal_amount = clamp(target_member.actual_stats.health + (GlobalCombatInformation.all_party_slots[caster_index].actual_stats.magic + skill_used.get_skill_boost()), 0, target_member.actual_stats.max_health)
			else:
				heal_amount = target_member.actual_stats.max_health
				
			target_member.heal(skill_used, GlobalCombatInformation.all_party_slots[caster_index])
			menu_tabs.get_child(caster_index).update_damage_label(heal_amount)
			GlobalCombatInformation.current_BP -= skill_used.mana_cost
			_revert_to_caster() 
			return
			
		elif skill_used.aoe_heal:
			if not _is_any_party_member_damaged():

				_reject_cast_and_restore_visuals()
				return
				
			for person in range(GlobalCombatInformation.all_party_slots.size()):
				var heal_amount = 0
				if skill_used.get_skill_boost() != 999:
					heal_amount = clamp((GlobalCombatInformation.all_party_slots[caster_index].actual_stats.magic + skill_used.get_skill_boost()), 0, GlobalCombatInformation.all_party_slots[person].actual_stats.max_health)
				else:
					heal_amount = GlobalCombatInformation.all_party_slots[person].actual_stats.max_health
				GlobalCombatInformation.all_party_slots[person].heal(skill_used, GlobalCombatInformation.all_party_slots[caster_index])
				menu_tabs.get_child(person).update_damage_label(heal_amount)
			GlobalCombatInformation.current_BP -= skill_used.mana_cost
			_revert_to_caster() 
			return
			
		else:
			var target_member = GlobalCombatInformation.all_party_slots[tab]
			if target_member.actual_stats.health >= target_member.actual_stats.max_health:

				_reject_cast_and_restore_visuals()
				return
				
			var heal_amount = 0
			if skill_used.get_skill_boost() != 999:
				heal_amount = clamp((GlobalCombatInformation.all_party_slots[caster_index].actual_stats.magic + skill_used.get_skill_boost()), 0, target_member.actual_stats.max_health)
			else:
				heal_amount = target_member.actual_stats.max_health
				
			target_member.heal(skill_used, GlobalCombatInformation.all_party_slots[caster_index])
			menu_tabs.get_child(tab).update_damage_label(heal_amount)
			
			GlobalCombatInformation.current_BP -= skill_used.mana_cost
			
			_revert_to_caster() 
			return
		
	menu_tabs.current_selection = tab
	for child in skill_card_container.get_children():
		if child.get_index() == tab:
			child.visible = true
			$Skill_Description/AnimatedSprite2D.sprite_frames = GlobalCombatInformation.all_party_slots[child.get_index()].sprite_frames
			_trigger_default_skill_selection(child)
		else:
			child.visible = false

func _revert_to_caster() -> void:
	trying_to_use_skill = false
	skill_used = null
	$Panel/Label.text = "Use"

	for child in menu_tabs.get_children():
		child.update_highlight(child.get_index() == caster_index) 
		_set_node_mouse_disabled(child, false)
		
	_is_snapping_back = true
	menu_tabs.current_selection = caster_index 
	if menu_tabs.has_method("cycle_input"):
		menu_tabs.cycle_input(null, -1000)
		menu_tabs.cycle_input(null, caster_index)
	_is_snapping_back = false
	
	for child in skill_card_container.get_children():
		if child.get_index() == caster_index:
			child.visible = true
			$Skill_Description/AnimatedSprite2D.sprite_frames = GlobalCombatInformation.all_party_slots[child.get_index()].sprite_frames
		else:
			child.visible = false
			
	if active_skill_instance_id != -1:
		update_skill_description(active_skill_instance_id)

func _reject_cast_and_restore_visuals() -> void:
	_is_snapping_back = true
	menu_tabs.current_selection = caster_index 
	if menu_tabs.has_method("cycle_input"):
		menu_tabs.cycle_input(null, -1000)
		menu_tabs.cycle_input(null, caster_index) 
	_is_snapping_back = false

	if skill_used.aoe_heal:
		for child in menu_tabs.get_children():
			child.update_highlight(true)
	else:
		for child in menu_tabs.get_children():
			child.update_highlight(child.get_index() == caster_index)

func _trigger_default_skill_selection(card_node: Node) -> void:
	if card_node.get_child_count() > 0:
		var moves_node = card_node.get_child(0) 
		if moves_node.get_child_count() > 0:
			var first_move = moves_node.get_child(0)
			update_skill_description(first_move.get_instance_id())

func update_skill_description(pressed_skill):
	active_skill_instance_id = pressed_skill
	
	var selected_skill: moves
	var move_index: int
	for move in skill_card_container.get_child(menu_tabs.current_selection).get_child(0).get_children():
		if move.get_instance_id() == pressed_skill:
			selected_skill = GlobalCombatInformation.all_party_slots[menu_tabs.current_selection].combatant_skills[move.get_index()]
			move_index = move.get_index()
			if move.has_method("update_selection"):
				move.update_selection(true)
		else:
			if move.has_method("update_selection"):
				move.update_selection(false)
				
	if selected_skill == null:
		return
	$Skill_Description/TextureRect.texture = selected_skill.move_sprite if selected_skill.move_sprite != null else null
	$Skill_Description/Label.text = selected_skill.move_description
	$Skill_Description/Label2.text = selected_skill.move_name
	$Skill_Description/Label3.text = str(selected_skill.mana_cost) + " BP"
	if $Skill_Description/AnimatedSprite2D.sprite_frames.has_animation("On_Attack_" + str(move_index + 1)):
		$Skill_Description/AnimatedSprite2D.play("On_Attack_" + str(move_index + 1))
	
	if selected_skill.does_heal_party:
		$Panel.visible = true
		$Button_Background.visible = true
		if GlobalCombatInformation.current_BP < selected_skill.mana_cost:
			$Panel/Label.text = "LOW BP"
		else:
			$Panel/Label.text = "Use"
	else:
		$Panel.visible = false
		$Button_Background.visible = false

func _ready_to_use_skill(skill_to_use: moves):
	if not skill_to_use.does_heal_party:
		return
	skill_used = skill_to_use
	
	caster_index = menu_tabs.current_selection
	trying_to_use_skill = true
	
	if skill_to_use.aoe_heal:
		for child in menu_tabs.get_children():
			child.highlight(true)
			_set_node_mouse_disabled(child, false)
	elif skill_to_use.targets_self:
		for child in menu_tabs.get_children():
			if child.get_index() == caster_index:
				child.highlight(true)
				_set_node_mouse_disabled(child, false)
			else:
				child.highlight(false)
				_set_node_mouse_disabled(child, true) 
	else:
		for child in menu_tabs.get_children():
			child.update_highlight(child.get_index() == caster_index)
			_set_node_mouse_disabled(child, false)

func _set_node_mouse_disabled(node: Node, disabled: bool) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_PASS
	if node is BaseButton:
		node.disabled = disabled
	for child in node.get_children():
		_set_node_mouse_disabled(child, disabled)

func _input(event: InputEvent) -> void:
	if trying_to_use_skill:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()

func _is_any_party_member_damaged() -> bool:
	for member in GlobalCombatInformation.all_party_slots:
		if member.actual_stats.health < member.actual_stats.max_health:
			return true
	return false

func _on_panel_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			accept_event() 
			if not trying_to_use_skill:
				var selected_skill
				for child in skill_card_container.get_child(menu_tabs.current_selection).get_child(0).get_children():
					if child.is_selected:
						selected_skill = child
						break
				var skill = GlobalCombatInformation.all_party_slots[menu_tabs.current_selection].combatant_skills[selected_skill.get_index()]
				
				if GlobalCombatInformation.current_BP < skill.mana_cost:
					return
					
				_ready_to_use_skill(skill)
				$Panel/Label.text = "Cancel"
			else:
				_revert_to_caster()

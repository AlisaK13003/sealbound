extends Control

class_name dungeon_gui

@onready var options_menu = $Options_Menu
@onready var item_menu = $Item_Menu
@onready var skill_menu = $Skill_Menu
@onready var base_menu = $Control

@onready var item_button = $Control/Base_Menu/Item
@onready var skill_button = $Control/Base_Menu/Skill
@onready var attack_button = $Control/Base_Menu/Attack
@onready var option_button = $Control/Base_Menu/Options
@onready var bond_attack_button = $Bond_Attack_Button

@onready var confirmation_yes = $Confirmation/GenericButton
@onready var confirmation_no = $Confirmation/GenericButton2
@onready var confirmation_button = $Confirmation

@onready var back_button_ = $Action_Hint/MarginContainer/HBoxContainer/Back_Button
@onready var targeting = $Action_Hint/Targetting
@onready var confirm = $Action_Hint/MarginContainer/HBoxContainer/Confirm

@onready var selection_area = $Selection_Indicator

@onready var black_box = $ColorRect

@onready var portrait_container = $Party_Portrait_Container
@onready var mana_label = $"Mana Bar/HBoxContainer/Label"
@onready var bond_bar = $Bond_Attack

@onready var action_hint_area = $Action_Hint

@onready var action_queue_list = $Control/ActionQueue

var test_mode = false

var p_ref: dungeon_loop

var executing_skill = false
var executing_item = false
var is_aoe = false

var has_been_setup: bool = false

signal basic_attack
signal skill_used
signal item_used
signal defended
signal run_action

func _setup(parent_reference):
	black_box.visible = true
	
	if not has_been_setup:
		item_button.activated.connect(_item_menu_pressed)
		skill_button.activated.connect(_skill_menu_pressed)
		attack_button.activated.connect(_base_attack_emitted)
		option_button.activated.connect(options_menu_option)
		confirmation_yes.activated.connect(confirmation_button_.bind(true))
		confirmation_no.activated.connect(confirmation_button_.bind(false))
		back_button_.activated.connect(_back_button_pressed)
		confirm.activated.connect(_confirm_button_pressed)
		
		$Action_Hint/Targetting/Target_L.activated.connect(parent_reference.update_selected_enemy.bind(-1))
		$Action_Hint/Targetting/Target_R.activated.connect(parent_reference.update_selected_enemy.bind(1))
		
		basic_attack.connect(parent_reference.basic_attack)
		skill_used.connect(parent_reference.skill_used)
		item_used.connect(parent_reference.item_used)
		defended.connect(parent_reference.player_defended)
		run_action.connect(parent_reference.ran_from_combat)
		$Bond_Attack_Button/GenericButton.activated.connect(parent_reference.player_did_bond_attack)
		
	base_menu.visible = true
	self.visible = true
	p_ref = parent_reference

	var tween = create_tween()
	tween.tween_property(black_box, "modulate:a", 0.0, 1)
	await tween.finished
	black_box.visible = false

	bond_bar.value = GlobalCombatInformation.cur_bond_attack_val
	bond_bar.max_value = GlobalCombatInformation.max_BP * 2
	has_been_setup = true

func run_button_pressed():
	p_ref.action_taken.emit(["RUN", ""])

func hide_gui(show_back_button):
	item_menu.visible = false
	skill_menu.visible = false
	back_button_.visible = show_back_button
	selection_area.visible = false
	base_menu.visible = false

func show_base_gui():
	base_menu.visible = true
	selection_area.visible = true
	update_action_hints()

func new_player_turn():
	swap_to_new_player()
	action_queue_list.update_turn_queue_ui(p_ref.all_combatants)

func update_turn_queue_ui():
	action_queue_list.update_turn_queue_ui(p_ref.all_combatants)

func swap_to_new_player():
	executing_item = false
	executing_skill = false
	skill_menu._setup(GlobalCombatInformation.active_party_slots[p_ref.active_player_turn].combatant_skills_)
	item_menu._setup()
	options_menu._setup()
	if not skill_menu.thing_selected.is_connected(_display_enemy_selection):
		skill_menu.thing_selected.connect(_display_enemy_selection)
	if not item_menu.thing_selected.is_connected(_display_enemy_selection):
		item_menu.thing_selected.connect(_display_enemy_selection)
	if not options_menu.thing_selected.is_connected(handle_option_selection):
		options_menu.thing_selected.connect(handle_option_selection)
	
	show_base_gui()

func handle_option_selection(option_index):
	match option_index:
		# Defend
		0:
			_thought_about_defending()
		# Run
		1:
			run_action.emit()
		2:
			print("You are trying to view the queue")

func _base_attack_emitted():
	if base_menu.visible:
		base_menu.visible = false
		basic_attack.emit()
		hide_gui(false)

func _thought_about_defending():
	base_menu.visible = false
	hide_gui(false)
	p_ref.unselect_all()
	setup_confirmation_button("Defend", p_ref.get_player(p_ref.active_player_turn).stored_combatant)

func options_menu_option():
	if base_menu.visible:
		selection_area.visible = false
		p_ref.no_one_can_be_selected()
		options_menu.visible = true
		base_menu.visible = false
		back_button_.visible = true
	update_action_hints()
		
func confirmation_button_(confirm_or_deny):
	if confirm_or_deny:
		defended.emit()
	else:
		$Confirmation.visible = false
		$Options_Menu.visible = true
		update_action_hints()

func _back_button_pressed():
	if base_menu.visible:
		return
	p_ref.unselect_all()
	if executing_item:
		item_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_item = false
		selection_area.visible = false
		update_action_hints()
	elif executing_skill:
		skill_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_skill = false
		selection_area.visible = false
		update_action_hints()
	elif skill_menu.visible or item_menu.visible or options_menu.visible:
		item_menu.visible = false
		skill_menu.visible = false
		options_menu.visible = false
		back_button_.visible = false
		base_menu.visible = true
		p_ref.select_individual(false, 0)
		p_ref.make_enemies_selectable()
		selection_area.visible = true
		update_action_hints()

func _confirm_button_pressed():
	if item_menu.visible:
		item_menu.node_selected()
	elif skill_menu.visible:
		skill_menu.node_selected()
	elif options_menu.visible:
		options_menu.node_selected()
	else:
		if executing_item:
			execute_item()
			selection_area.visible = false
		elif executing_skill:
			execute_skill()
			selection_area.visible = false
	update_action_hints()

signal confirmation_given
func execute_skill():
	$Action_Hint.visible = false
	skill_used.emit(skill_menu.selected_item, skill_menu.selected_item_index)

func execute_item():
	$Action_Hint.visible = false
	item_used.emit(item_menu.selected_item, item_menu.selected_item_index)

func _skill_menu_pressed():
	if base_menu.visible:
		selection_area.visible = false
		p_ref.no_one_can_be_selected()
		skill_menu.visible = true
		base_menu.visible = false
		back_button_.visible = true
	update_action_hints()
	
func _item_menu_pressed():
	if base_menu.visible:
		selection_area.visible = false
		p_ref.no_one_can_be_selected()
		item_menu.visible = true
		base_menu.visible = false
		back_button_.visible = true
	update_action_hints()
	
signal display_enemies
func _display_enemy_selection(thing_used):
	p_ref.can_select_things(thing_used)
	if thing_used is Items:
		executing_item = true
		is_aoe = thing_used.is_aoe_item
		
		if thing_used.does_what == 2:
			if is_aoe:
				p_ref.no_one_can_be_selected()
				p_ref.select_all_players()
				update_selection_section(null)
			else:
				p_ref.make_players_selectable()
				p_ref.select_individual(true, p_ref.active_player_turn)
				update_selection_section(p_ref.get_player(p_ref.active_player_turn))
		else:
			if is_aoe:
				p_ref.no_one_can_be_selected()
				p_ref.select_all_enemies()
				update_selection_section(null)
			else:
				p_ref.no_one_can_be_selected()
				p_ref.make_enemies_selectable()
				p_ref.select_individual(false, 0)
				update_selection_section(p_ref.enemy_shit.get_child(0))
		
		display_enemies.emit(thing_used.is_aoe_item, true if thing_used.does_what & 10 else false, false)
	elif thing_used is moves:
		executing_skill = true
		is_aoe = thing_used.is_skill_aoe
		if thing_used.targets_party:
			if thing_used.targets_self:
				p_ref.no_one_can_be_selected()
				p_ref.select_individual(true, p_ref.active_player_turn)
				update_selection_section(p_ref.get_player(p_ref.active_player_turn))
			elif is_aoe:
				p_ref.no_one_can_be_selected()
				p_ref.select_all_players()
				update_selection_section(null)
			else:
				p_ref.make_players_selectable()
				p_ref.select_individual(true, p_ref.active_player_turn)
				update_selection_section(p_ref.get_player(p_ref.active_player_turn))
		else:
			if is_aoe:
				p_ref.select_all_enemies()
				update_selection_section(null)
			else:
				p_ref.make_enemies_selectable()
				p_ref.select_individual(false, 0)
				update_selection_section(p_ref.enemy_shit.get_child(0))
		
		display_enemies.emit(thing_used.is_skill_aoe, thing_used.targets_party, thing_used.targets_self)
	selection_area.visible = true

func setup_confirmation_button(move_name, used_on: generic_combatants):
	confirmation_button.visible = true
	var question_label = confirmation_button.get_child(0)
	question_label.text = "Use " + move_name + " on " + used_on.combatant_name + "?"

func update_action_hints():
	$Action_Hint.visible = true
	if base_menu.visible:
		targeting.visible = true; confirm.visible = false; back_button_.visible = false
	elif skill_menu.visible or item_menu.visible or options_menu.visible:
		confirm.visible = true; back_button_.visible = true; targeting.visible = false
	elif executing_item or executing_skill:
		confirm.visible = true; back_button_.visible = true; targeting.visible = not is_aoe

func update_selection_section(combatant: combat_template):
	if executing_item:
		$Selection_Indicator/GridContainer/TextureRect.texture = item_menu.selected_item.item_sprite if item_menu.selected_item.item_sprite != null else load("res://assets/Equipment/Equipment Sprites/Feet.png")
		$Selection_Indicator/GridContainer/Enemy_Name2.text = item_menu.selected_item.item_name
	elif executing_skill:
		$Selection_Indicator/GridContainer/TextureRect.texture = skill_menu.selected_item.move_sprite if skill_menu.selected_item.move_sprite != null else load("res://assets/Equipment/Equipment Sprites/Feet.png")
		$Selection_Indicator/GridContainer/Enemy_Name2.text = skill_menu.selected_item.move_name
	else:
		$Selection_Indicator/GridContainer/TextureRect.texture = load("res://assets/Equipment/Equipment Sprites/Feet.png")
		$Selection_Indicator/GridContainer/Enemy_Name2.text = "Base Attack"
	
	if is_aoe:
		$Selection_Indicator/GridContainer/Enemy_Level.text = "All"
		$Selection_Indicator/GridContainer/Enemy_Name.text = ""
	else:
		$Selection_Indicator/GridContainer/Enemy_Level.text = "Lv. " + str(combatant.stored_combatant.actual_stats.level)
		$Selection_Indicator/GridContainer/Enemy_Name.text = combatant.stored_combatant.combatant_name
	#if combatant.stored_combatant.is_combatant_enemy:
	#	$Selection_Indicator/GridContainer/Enemy_Level.text = "Lv " + str(combatant.stored_combatant.combatant_stats.level)

	#selection_area.get_child(0).get_child(1).text = combatant.stored_combatant.combatant_name

func get_player_portrait(portrait_to_get: int):
	if portrait_to_get > 3:
		print("UGH")
	return portrait_container.get_child(portrait_to_get)

func update_mana_display(mana_used_or_gained, setup):
	if setup:
		mana_label.text = str(p_ref.current_bond_points) + "/" + str(p_ref.max_bond_points_)
		set_bond_attack(GlobalCombatInformation.cur_bond_attack_val)
		return p_ref.current_bond_points
	p_ref.current_bond_points = clamp(p_ref.current_bond_points + mana_used_or_gained, 0, p_ref.max_bond_points_)
	mana_label.text = str(p_ref.current_bond_points) + "/" + str(p_ref.max_bond_points_)
	update_bond_attack(mana_used_or_gained)
	return p_ref.current_bond_points

func set_bond_attack(value):
	bond_bar.value = clamp(abs(value), 0, bond_bar.max_value)

func update_bond_attack(update_value):
	bond_bar.value += clamp(abs(update_value), 0, bond_bar.max_value)

func _on_button_pressed():
	bond_bar.value += 1

func _on_bond_attack_value_changed(value):
	if bond_bar.value == bond_bar.max_value:
		$Bond_Attack_Button.visible = true
	else:
		$Bond_Attack_Button.visible = false

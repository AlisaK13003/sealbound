extends Control

class_name dungeon_gui

@onready var item_menu = $Item_Menu
@onready var skill_menu = $Skill_Menu
@onready var base_menu = $NinePatchRect/Base_Menu
@onready var base_menu_nine = $NinePatchRect

@onready var item_button = $NinePatchRect/Base_Menu/Item
@onready var skill_button = $NinePatchRect/Base_Menu/Skill
@onready var attack_button = $NinePatchRect/Base_Menu/Attack
@onready var defend_button = $NinePatchRect/Base_Menu/Defend
@onready var run_button = $GenericButton

@onready var confirmation_yes = $Confirmation/GenericButton
@onready var confirmation_no = $Confirmation/GenericButton2
@onready var confirmation_button = $Confirmation

@onready var back_button_ = $Action_Hint/Back_Button
@onready var targeting = $Action_Hint/Targetting
@onready var confirm = $Action_Hint/Confirm

@onready var selection_area = $Panel

@onready var black_box = $ColorRect
@onready var dungeon_floor_label = $NinePatchRect3
@onready var dungeon_floor_text = $NinePatchRect3/Dungeon_Floor
@onready var previous_floor_label = $NinePatchRect3/Dungeon_Floor/MarginContainer/VBoxContainer/Previous_floor
@onready var current_floor_label = $NinePatchRect3/Dungeon_Floor/MarginContainer/VBoxContainer/Current_Floor
@onready var floor_label_container = $NinePatchRect3/Dungeon_Floor/MarginContainer

@onready var portrait_container = $Upper_Bar/HBoxContainer/MarginContainer/Party_Portraits/HBoxContainer
@onready var mana_label = $"Upper_Bar/HBoxContainer/Mana Bar/Label"

var test_mode = false

var p_ref: dungeon_loop

var executing_skill = false
var executing_item = false
var is_aoe = false

@export var how_long_should_base_menu_be: int = 300

func _ready():
	black_box.visible = true
	dungeon_floor_label.visible = true
	if test_mode:
		await GlobalCombatInformation.load_items()
		item_menu._setup(GlobalCombatInformation.all_held_items, self, "I/nt/ne/nm/ns")
		skill_menu._setup(GlobalCombatInformation.active_party_slots[2].combatant_skills, self, "S/nk/ni/nl/nl\ns")
	item_button.activated.connect(_item_menu_pressed)
	skill_button.activated.connect(_skill_menu_pressed)
	attack_button.activated.connect(_base_attack_emitted)
	defend_button.activated.connect(_defend_executed)
	run_button.activated.connect(run_button_pressed)
	confirmation_yes.activated.connect(confirmation_button_.bind(true))
	confirmation_no.activated.connect(confirmation_button_.bind(false))
	back_button_.activated.connect(_back_button_pressed)
	confirm.activated.connect(_confirm_button_pressed)
	await unfurl_base_menu(true)

func unfurl_base_menu(open):
	base_menu_nine.visible = open
	var tween = create_tween()
	tween.tween_property(base_menu_nine, "size:x", (custom_minimum_size.x + how_long_should_base_menu_be if open else 0), 0.5)
	update_action_hints()
	
func run_button_pressed():
	p_ref.action_taken.emit(["RUN", ""])

func _setup(parent_reference):
	self.visible = true
	p_ref = parent_reference
	dungeon_floor_text.text = parent_reference.current_dungeon_run.dungeon_name
	floor_label_container.visible = false

	await get_tree().create_timer(2).timeout
	var tween = create_tween()
	tween.tween_property(black_box, "modulate:a", 0.0, 1)
	await tween.finished
	black_box.visible = false
	dungeon_floor_label.visible = false
	floor_label_container.visible = true
	show_base_gui()

func _input(event):
	if Input.is_action_just_pressed("down"):
		cycle_inside_menu(false)
	elif Input.is_action_just_pressed("left") and p_ref.selecting_entity:
		p_ref.update_selected_enemy(-1)
	elif Input.is_action_just_pressed("right") and p_ref.selecting_entity:
		p_ref.update_selected_enemy(1)
	elif Input.is_action_just_pressed("up"):
		cycle_inside_menu(true)
					
func cycle_inside_menu(up_or_down):
	if item_menu.visible:
		item_menu.update_selection(-1 if up_or_down else 1)
	elif skill_menu.visible:
		skill_menu.update_selection(-1 if up_or_down else 1)
		
func hide_gui(show_back_button):
	item_menu.visible = false
	skill_menu.visible = false
	await unfurl_base_menu(false)
	back_button_.visible = show_back_button
	selection_area.visible = false
	$Action_Hint.visible = false

func show_base_gui():
	await unfurl_base_menu(true)
	selection_area.visible = true
	$Action_Hint.visible = true
	update_action_hints()

func new_player_turn(item_list):
	swap_to_new_player(item_list)

func swap_to_new_player(item_list):
	show_base_gui()
	executing_item = false
	executing_skill = false
	await item_menu._setup(item_list, p_ref, "Items")
	await skill_menu._setup(p_ref.get_player(p_ref.active_player_turn).stored_combatant.combatant_skills, p_ref, "Skills")

func _base_attack_emitted():
	if base_menu_nine.visible and base_menu_nine.size.x == how_long_should_base_menu_be:
		p_ref.attack_button_pressed()
		hide_gui(false)

func _defend_executed():
	if base_menu_nine.visible and base_menu_nine.size.x == how_long_should_base_menu_be:
		p_ref.defend_button_pressed()
		hide_gui(false)

func _back_button_pressed():
	if executing_item:
		item_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_item = false
		selection_area.visible = false
	elif executing_skill:
		skill_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_skill = false
		selection_area.visible = false
	elif skill_menu.visible or item_menu.visible:
		item_menu.visible = false
		skill_menu.visible = false
		back_button_.visible = false
		await unfurl_base_menu(true)
		p_ref.select_individual(false, 0)
		p_ref.make_enemies_selectable()
		selection_area.visible = true
	update_action_hints()

func _confirm_button_pressed():
	if item_menu.visible:
		item_menu.selection_confirmed()
		selection_area.visible = not is_aoe
	elif skill_menu.visible:
		if skill_menu.selection_confirmed():
			selection_area.visible = not is_aoe
	elif executing_item:
		if item_menu.execute_selection():
			selection_area.visible = false
	elif executing_skill:
		skill_menu.execute_selection()
		selection_area.visible = false
	update_action_hints()

func _skill_menu_pressed():
	if base_menu_nine.visible:
		selection_area.visible = false
		p_ref.no_one_can_be_selected()
		skill_menu.visible = true
		await unfurl_base_menu(false)
		back_button_.visible = true
		skill_menu.drop_and_swing_in()
	update_action_hints()
	
func _item_menu_pressed():
	if base_menu_nine.visible:
		selection_area.visible = false
		p_ref.no_one_can_be_selected()
		item_menu.visible = true
		await unfurl_base_menu(false)
		item_menu.drop_and_swing_in()
		back_button_.visible = true
	update_action_hints()

func _executing_item(yes_or_no, item_aoe):
	executing_item = yes_or_no
	is_aoe = item_aoe

func _executing_skill(yes_or_no, skill_aoe):
	executing_skill = yes_or_no
	is_aoe = skill_aoe

func confirmation_button_(confirm_or_deny):
	p_ref.actual_confirmation.emit(confirm_or_deny)

func setup_confirmation_button(move_name, entity_used_on_name, used_on):
	if used_on is generic_combatants and not used_on.is_combatant_enemy:
		p_ref.sci_fi_enhance_zoom(p_ref.get_camera_offset(true, p_ref.active_player_turn))
	elif used_on is combat_template:
		if used_on.stored_combatant.is_combatant_enemy:
			p_ref.sci_fi_enhance_zoom(p_ref.get_camera_offset(false, used_on.child_number))
		else:
			p_ref.sci_fi_enhance_zoom(p_ref.get_camera_offset(true, used_on.child_number))
	elif used_on == 4:
		p_ref.sci_fi_enhance_zoom(p_ref.get_camera_offset(true, 4))
	elif used_on == 5:
		p_ref.sci_fi_enhance_zoom(p_ref.get_camera_offset(false, 6))
	confirmation_button.visible = true
	var question_label = confirmation_button.get_child(0)
	question_label.text = "Use " + move_name + " on " + entity_used_on_name + "?"

func update_action_hints():
	$Action_Hint.visible = true
	if base_menu_nine.visible:
		targeting.visible = true; confirm.visible = false; back_button_.visible = false
		return
	if skill_menu.visible or item_menu.visible:
		confirm.visible = true; back_button_.visible = true; targeting.visible = false
	if executing_item or executing_skill:
		confirm.visible = true; back_button_.visible = true; targeting.visible = not is_aoe

func update_selection_section(combatant: combat_template):
	if combatant.stored_combatant.is_combatant_enemy:
		selection_area.get_child(0).get_child(0).text = "Lv " + str(combatant.stored_combatant.combatant_stats.level)
	else:
		selection_area.get_child(0).get_child(0).text = "             "
	selection_area.get_child(0).get_child(1).text = combatant.stored_combatant.combatant_name

func get_player_portrait(portrait_to_get: int):
	if portrait_to_get > 3:
		print("UGH")
	return portrait_container.get_child(portrait_to_get)

func update_mana_display(mana_used_or_gained):
	p_ref.current_bond_points = clamp(p_ref.current_bond_points + mana_used_or_gained, 0, p_ref.max_bond_points_)
	mana_label.text = str(p_ref.current_bond_points) + "/" + str(p_ref.max_bond_points_)
	return p_ref.current_bond_points

func next_floor(current_floor):
	black_box.visible = true
	dungeon_floor_label.visible = true
	
	current_floor_label.text = str(current_floor + 1) + "F"
	previous_floor_label.text = str(current_floor + 2) + "F"
	
	black_box.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(black_box, "modulate:a", 1.0, 0.5)
	
	await tween.finished
	
	tween = create_tween()
	tween.tween_property(floor_label_container, "theme_override_constants/margin_top", 126, 2)
		
	await tween.finished
	await get_tree().create_timer(1).timeout
	tween = create_tween()
	tween.tween_property(black_box, "modulate:a", 0, 0.5)
	
	dungeon_floor_label.visible = false
	tween = create_tween()
	tween.tween_property(floor_label_container, "theme_override_constants/margin_top", -124, 1)
	await get_tree().create_timer(2).timeout

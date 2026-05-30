extends Control

class_name dungeon_gui

@onready var item_menu = $CanvasLayer/Item_Menu
@onready var skill_menu = $CanvasLayer/Skill_Menu
@onready var base_menu = $CanvasLayer/Base_Menu
@onready var back_button = $CanvasLayer/TextureButton

# Key prompts
@onready var item_menu_prompt = $CanvasLayer/Base_Menu/Item_Menu_Button/Label
@onready var skill_menu_prompt = $CanvasLayer/Base_Menu/Skill_Menu_Button/Label2
@onready var attack_menu_prompt = $CanvasLayer/Base_Menu/Attack_Button/Label3
@onready var defend_menu_prompt = $CanvasLayer/Base_Menu/Defend_Button/Label4

var test_mode = false

var p_ref: dungeon_loop

var executing_skill = false
var executing_item = false

func _ready():
	if test_mode:
		await GlobalCombatInformation.load_items()
		item_menu._setup(GlobalCombatInformation.all_held_items, self, "Items")
		skill_menu._setup(GlobalCombatInformation.active_party_slots[2].combatant_skills, self, "Skills")
	var event_to_check = InputMap.action_get_events("Dungeon_Items")[0]
	var incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
	item_menu_prompt.text = OS.get_keycode_string(incoming_key)
	event_to_check = InputMap.action_get_events("Dungeon_Skill")[0]
	incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
	skill_menu_prompt.text = OS.get_keycode_string(incoming_key)
	event_to_check = InputMap.action_get_events("Dungeon_Attack")[0]
	incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
	attack_menu_prompt.text = OS.get_keycode_string(incoming_key)
	event_to_check = InputMap.action_get_events("Dungeon_Defend")[0]
	incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
	defend_menu_prompt.text = OS.get_keycode_string(incoming_key)


func _setup(parent_reference):
	p_ref = parent_reference

func _input(event):
	if Input.is_action_just_pressed("down"):
		cycle_inside_menu(false)
	elif Input.is_action_just_pressed("left") and p_ref.selecting_entity:
		p_ref.update_selected_enemy(1)
	elif Input.is_action_just_pressed("right") and p_ref.selecting_entity:
		p_ref.update_selected_enemy(-1)
	elif Input.is_action_just_pressed("up"):
		cycle_inside_menu(true)
		
	if base_menu.visible:
		if Input.is_action_just_pressed("Dungeon_Attack"):
			_base_attack_emitted()
		elif Input.is_action_just_pressed("Dungeon_Items"):
			_item_menu_pressed()
		elif Input.is_action_just_pressed("Dungeon_Skill"):
			_skill_menu_pressed()
		elif Input.is_action_just_pressed("Dungeon_Defend"):
			_defend_executed()
			
	if Input.is_action_just_pressed("Cancel"):
		_back_button_pressed()
	elif Input.is_action_just_pressed("Confirm"):
		_confirm_button_pressed()
		


func cycle_inside_menu(up_or_down):
	if item_menu.visible:
		item_menu.update_selection(-1 if up_or_down else 1)
	elif skill_menu.visible:
		skill_menu.update_selection(-1 if up_or_down else 1)
		
func hide_gui(show_back_button):
	item_menu.visible = false
	skill_menu.visible = false
	base_menu.visible = false
	back_button.visible = show_back_button

func show_base_gui():
	base_menu.visible = true

func new_player_turn(item_list):
	swap_to_new_player(item_list)

func swap_to_new_player(item_list):
	show_base_gui()
	executing_item = false
	executing_skill = false
	await item_menu._setup(item_list, p_ref, "Items")
	await skill_menu._setup(p_ref.get_player(p_ref.active_player_turn).stored_combatant.combatant_skills, p_ref, "Skills")

func _base_attack_emitted():
	p_ref.attack_button_pressed()
	hide_gui(false)

func _defend_executed():
	p_ref.defend_button_pressed()
	hide_gui(false)

func _back_button_pressed():
	if skill_menu.visible or item_menu.visible:
		base_menu.visible = true
		item_menu.visible = false
		skill_menu.visible = false
		p_ref.make_enemies_selectable()
		p_ref.select_individual(false, 0)
	elif executing_item:
		item_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_item = false
	elif executing_skill:
		skill_menu.visible = true
		p_ref.confirmation.emit(false)
		executing_skill = false

func _confirm_button_pressed():
	if item_menu.visible:
		item_menu.selection_confirmed()
	elif skill_menu.visible:
		skill_menu.selection_confirmed()
	elif executing_item:
		item_menu.execute_selection()
	elif executing_skill:
		skill_menu.execute_selection()

func _skill_menu_pressed():
	p_ref.no_one_can_be_selected()
	back_button.visible = true
	skill_menu.visible = true
	base_menu.visible = false
	
func _item_menu_pressed():
	p_ref.no_one_can_be_selected()
	item_menu.visible = true
	base_menu.visible = false
	back_button.visible = true

func _executing_item(yes_or_no):
	executing_item = yes_or_no
	
func _executing_skill(yes_or_no):
	executing_skill = yes_or_no

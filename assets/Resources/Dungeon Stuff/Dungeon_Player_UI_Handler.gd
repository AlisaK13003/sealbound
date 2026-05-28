extends Control

class_name dungeon_gui

@onready var item_menu = $CanvasLayer/Item_Menu
@onready var skill_menu = $CanvasLayer/Skill_Menu
@onready var base_menu = $CanvasLayer/Base_Menu
@onready var back_button = $CanvasLayer/TextureButton
var test_mode = false

var p_ref: dungeon_loop

var executing_skill = false
var executing_item = false

func _ready():
	if test_mode:
		await GlobalCombatInformation.load_items()
		item_menu._setup(GlobalCombatInformation.all_held_items, self, "Items")
		skill_menu._setup(GlobalCombatInformation.active_party_slots[2].combatant_skills, self, "Skills")

func _setup(parent_reference):
	p_ref = parent_reference

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

func _executing_item():
	executing_item = true
	
func _executing_skill():
	executing_skill = true

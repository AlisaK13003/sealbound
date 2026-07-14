extends Control

@onready var menu_tabs = $MenuTabs

@export var tab_icons: Array[Texture2D]

@export var shop_stock: Array

@export var shop_discount: float

var persistent_shop_stock
var persistent_sell_inventory

@onready var stock_container = $Stock_Container

var tabs : Array[String]
@export var is_player_selling: bool = false

@export_flags("Weapon", "Item", "Helmets", "Chestplate", "Boots", "Charms", "Valuables") var item_types_to_sell = 0

@onready var weapon_stock_container = $Stock_Container/Weapons
@onready var helmet_stock_container = $Stock_Container/Helmets
@onready var chestplate_stock_container = $Stock_Container/Chestplates
@onready var boot_stock_container = $Stock_Container/Boots
@onready var charm_stock_container = $Stock_Container/Charms
@onready var item_stock_container = $Stock_Container/Items
@onready var valuables_stock_container = $Stock_Container/Valuables

var scroll_container_path = "res://assets/Resources/Pause Menu/DIY_Scroll_Container.tscn"

func _ready():
	persistent_shop_stock = shop_stock.duplicate()
	_setup()
	
func fully_reset():
	shop_stock.clear()
	shop_stock = persistent_shop_stock.duplicate()
	
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
	
	for child in stock_container.get_children():
		child.wipe_clean()
	
	_setup()
	
	#_setup()
func update_money_total(old_money_count, differential):
	$Label.text = str(old_money_count)
	AudioManager.play_ui_sound(AudioManager.BUY_SELL_SOMETHING)
	for i in range(differential * -1):
		$Label.text = str(int($Label.text) + (-1 if differential < 0 else 1))
		await get_tree().create_timer(0.01).timeout

func _update_item_description(with_item):
	if with_item is Items:
		$Label2.text = with_item.item_description
	elif with_item is equipment:
		$Label2.text = with_item.equipment_description
	elif with_item is weapon:
		$Label2.text = with_item.weapon_description

func tab_changed(which_tab):
	for child in stock_container.get_children():
		if child.get_index() == which_tab:
			child.visible = true
		else:
			child.visible = false

func _setup():
	tabs = ["Weapons", "Helmets", "Chestplates", "Boots", "Charms", "Items", "Valuables"]
	
	if not menu_tabs.selection_changed.is_connected(tab_changed):
		menu_tabs.selection_changed.connect(tab_changed)

	menu_tabs._setup(tabs, "res://assets/Resources/Pause Menu/Custom_Menu_Tab.tscn")

	var found_item: bool = false
	var found_weapon: bool = false
	var found_equipment: bool = false

	var big_list = []
	
	if not is_player_selling:
		for item in shop_stock:
			if item is Items and not found_item:
				menu_tabs.get_child(0).visible = true
				found_item = true
			if item is weapon and not found_weapon:
				menu_tabs.get_child(1).visible = true
				menu_tabs.get_child(2).visible = true
				menu_tabs.get_child(3).visible = true
				menu_tabs.get_child(4).visible = true
				found_equipment = true
			if item is equipment and not found_equipment:
				menu_tabs.get_child(5).visible = true
				found_weapon = true
		if not found_item:
			menu_tabs.get_child(0).visible = false
		if not found_equipment:
			menu_tabs.get_child(1).visible = false
			menu_tabs.get_child(2).visible = false
			menu_tabs.get_child(3).visible = false
			menu_tabs.get_child(4).visible = false
		if not found_weapon:
			menu_tabs.get_child(5).visible = false
	else:
		#if item_types_to_sell & 0000001:
		#	menu_tabs.get_child(0).visible = true
		#if item_types_to_sell & 0000010:
		#	menu_tabs.get_child(1).visible = true
		#if item_types_to_sell & 0000100:
		#	menu_tabs.get_child(2).visible = true
		#if item_types_to_sell & 0001000:
		#	menu_tabs.get_child(3).visible = true
		#if item_types_to_sell & 0010000:
		#	menu_tabs.get_child(4).visible = true
		#if item_types_to_sell & 0100000:
		#	menu_tabs.get_child(5).visible = true
		#if item_types_to_sell & 1000000:
		#	menu_tabs.get_child(6).visible = true
		for child in menu_tabs.get_children():
			child.visible = true

		for item in GlobalCombatInformation.all_held_valuables:
			big_list.append(item)
		for item in GlobalCombatInformation.all_held_items:
			big_list.append(item)
		for item in GlobalCombatInformation.all_held_weapons:
			big_list.append(item)
		for item in GlobalCombatInformation.all_held_equipment:
			big_list.append(item)
		persistent_sell_inventory = big_list.duplicate()

	for tab in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(tab)._setup(tab_icons[tab])
	
	for child in range(stock_container.get_child_count()):
		if not is_player_selling:
			stock_container.get_child(child)._setup(tabs[child], shop_stock, shop_discount, is_player_selling)
			if not stock_container.get_child(child).update_item_description.is_connected(_update_item_description):
				stock_container.get_child(child).update_item_description.connect(_update_item_description)
		else:
			stock_container.get_child(child)._setup(tabs[child], big_list, shop_discount, is_player_selling)
			if not stock_container.get_child(child).update_item_description.is_connected(_update_item_description):
				stock_container.get_child(child).update_item_description.connect(_update_item_description)

	if not is_player_selling:
		for child in range(stock_container.get_child_count()):
			if stock_container.get_child(child).stock_container.get_child_count() == 0:
				stock_container.get_child(child).visible = false
				menu_tabs.get_child(child).visible = false
	$Label.text = str(GlobalCombatInformation.currency_held)
	menu_tabs.cycle_input(null, -1000)
	if not GlobalCombatInformation.did_something_with_money.is_connected(update_money_total):
		GlobalCombatInformation.did_something_with_money.connect(update_money_total)
	if not Global.day_passed.is_connected(fully_reset):	
		Global.day_passed.connect(fully_reset)
		
func populate_shop_stock(stock):
	for thing in stock:
		if thing is Items:
			item_stock_container._add_node(thing)
		elif thing is equipment:
			match thing.equipment_type:
				0:
					helmet_stock_container._add_node(thing)
				1:
					chestplate_stock_container._add_node(thing)
				2:
					boot_stock_container._add_node(thing)
				3:
					charm_stock_container._add_node(thing)
		elif thing is weapon:
			weapon_stock_container._add_node(thing)

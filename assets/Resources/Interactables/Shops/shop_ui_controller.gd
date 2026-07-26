extends Control

@onready var menu_tabs = $MenuTabs
@onready var owner_pic = $Background/TextureRect

@export var tab_icons: Array[Texture2D]
@export var shop_stock: Array
@export var shop_discount: float
@export var shope_portrait: Texture2D

var persistent_shop_stock: Array
var processed_shop_stock: Array
var persistent_sell_inventory: Array

@onready var stock_container = $Stock_Container

var tabs : Array[String]
@export var is_player_selling: bool = false
signal shop_closed
@export_flags("Weapon", "Item", "Helmets", "Chestplate", "Boots", "Charms", "Valuables") var item_types_to_sell = 0

@onready var weapon_stock_container = $Stock_Container/Weapons
@onready var helmet_stock_container = $Stock_Container/Helmets
@onready var chestplate_stock_container = $Stock_Container/Chestplates
@onready var boot_stock_container = $Stock_Container/Boots
@onready var charm_stock_container = $Stock_Container/Charms
@onready var item_stock_container = $Stock_Container/Items
@onready var valuables_stock_container = $Stock_Container/Valuables

var scroll_container_path = "res://assets/Resources/Pause Menu/DIY_Scroll_Container.tscn"

var current_tab_index: int = 0

func _ready():
	owner_pic.texture = shope_portrait
	persistent_shop_stock = shop_stock.duplicate()
	processed_shop_stock = process_stock_list(persistent_shop_stock)
	
	if is_player_selling:
		GlobalCombatInformation.equipment_added.connect(fully_reset.bind(false))
		GlobalCombatInformation.check_quest_progress.connect(fully_reset.bind(false))
	
	_setup()

func process_stock_list(raw_stock: Array) -> Array:
	var processed: Array = []
	var counts: Dictionary = {}
	
	for thing in raw_stock:
		if thing == null: continue
		var item_name = ""
		if thing is Items:
			item_name = thing.item_name
		elif thing is equipment:
			item_name = thing.equipment_name
		elif thing is weapon:
			item_name = thing.weapon_name
			
		if item_name != "":
			if counts.has(item_name):
				counts[item_name]["count"] += 1
			else:
				var item_copy = thing.duplicate()
				item_copy.set_meta("original_path", thing.resource_path) 
				counts[item_name] = { "item": item_copy, "count": 1 }
				processed.append(item_copy)
	
	for item_name in counts:
		counts[item_name]["item"].stack = counts[item_name]["count"]
		
	return processed

func fully_reset(pass_out = null):
	processed_shop_stock = process_stock_list(persistent_shop_stock)
	refresh_shop()

func refresh_shop():
	var saved_tab = current_tab_index
	
	for child in stock_container.get_children():
		child.wipe_clean()
		
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
	
	_setup()
	
	tab_changed(saved_tab)
	menu_tabs.cycle_input(null, saved_tab)

func update_money_total(old_money_count, differential):
	if not is_visible_in_tree():
		return
	
	$Label.text = str(old_money_count)
	AudioManager.play_ui_sound(AudioManager.BUY_SELL_SOMETHING)
	
	for i in range(differential if differential > 0 else -1 * differential):
		$Label.text = str(int($Label.text) + (-1 if differential < 0 else 1))
		await get_tree().create_timer(0.01).timeout
	$Label.text = str(GlobalCombatInformation.currency_held)
	refresh_shop()

func _update_item_description(with_item):
	if with_item is Items:
		$Label2.text = with_item.item_description
	elif with_item is equipment:
		$Label2.text = with_item.equipment_description + "; " + with_item.get_stat_string()
	elif with_item is weapon:
		$Label2.text = with_item.weapon_description + "; " + with_item.get_stat_string()

func tab_changed(which_tab):
	current_tab_index = which_tab
	for child in stock_container.get_children():
		if child.get_index() == which_tab:
			child.visible = true
		else:
			child.visible = false

func _setup():
	tabs = ["Weapons", "Helmets", "Chestplates", "Boots", "Charms", "Items", "Valuables"]
	
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
	
	if not menu_tabs.selection_changed.is_connected(tab_changed):
		menu_tabs.selection_changed.connect(tab_changed)

	menu_tabs._setup(tabs, "res://assets/Resources/Pause Menu/Custom_Menu_Tab.tscn")

	var found_item: bool = false
	var found_weapon: bool = false
	var found_equipment: bool = false

	var big_list = []
	var current_buy_stock = processed_shop_stock
	
	if not is_player_selling:
		for item in current_buy_stock:
			if item is Items and not found_item:
				menu_tabs.get_child(5).visible = true
				found_item = true
			if item is equipment and not found_equipment:
				menu_tabs.get_child(1).visible = true
				menu_tabs.get_child(2).visible = true
				menu_tabs.get_child(3).visible = true
				menu_tabs.get_child(4).visible = true
				found_equipment = true
			if item is weapon and not found_weapon:
				menu_tabs.get_child(0).visible = true
				found_weapon = true
		if not found_item:
			menu_tabs.get_child(5).visible = false
		if not found_equipment:
			menu_tabs.get_child(1).visible = false
			menu_tabs.get_child(2).visible = false
			menu_tabs.get_child(3).visible = false
			menu_tabs.get_child(4).visible = false
		if not found_weapon:
			menu_tabs.get_child(0).visible = false
	else:
		for child in menu_tabs.get_children():
			child.visible = true

		for item in GlobalCombatInformation.all_held_items:
			if item.what_is_it & 0b100:
				continue
			big_list.append(item)
		for item in GlobalCombatInformation.all_held_weapons:
			big_list.append(item)
		for item in GlobalCombatInformation.all_held_equipment:
			big_list.append(item)
		persistent_sell_inventory = big_list.duplicate()

	var max_icons = min(menu_tabs.get_child_count(), tab_icons.size())
	for tab in range(max_icons):
		menu_tabs.get_child(tab)._setup(tab_icons[tab])
	
	for child in range(stock_container.get_child_count()):
		if not is_player_selling:
			stock_container.get_child(child)._setup(tabs[child], current_buy_stock, shop_discount, is_player_selling)
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
	
	if not GlobalCombatInformation.did_something_with_money.is_connected(update_money_total):
		GlobalCombatInformation.did_something_with_money.connect(update_money_total)
	if not Global.day_passed.is_connected(fully_reset):	
		Global.day_passed.connect(fully_reset)

func _on_button_pressed():
	shop_closed.emit()

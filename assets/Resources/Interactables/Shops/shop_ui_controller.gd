extends Control

@onready var menu_tabs = $MenuTabs

@export_flags("Weapons", "Equipment", "Items") var what_things_do_I_sell = 2

@export var tab_icons: Array[Texture2D]

@export var shop_stock: Array

@export var shop_discount: float

var persistent_shop_stock

@onready var stock_container = $Stock_Container

var tabs : Array[String]


@onready var weapon_stock_container = $Stock_Container/Weapons
@onready var helmet_stock_container = $Stock_Container/Helmets
@onready var chestplate_stock_container = $Stock_Container/Chestplates
@onready var boot_stock_container = $Stock_Container/Boots
@onready var charm_stock_container = $Stock_Container/Charms
@onready var item_stock_container = $Stock_Container/Items

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
func update_money_total():
	$Label.text = str(GlobalCombatInformation.currency_held)

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
	tabs = ["Weapons", "Helmets", "Chestplates", "Boots", "Charms", "Items"]
	
	if not menu_tabs.selection_changed.is_connected(tab_changed):
		menu_tabs.selection_changed.connect(tab_changed)

	menu_tabs._setup(tabs, "res://assets/Resources/Pause Menu/Custom_Menu_Tab.tscn")

	if not what_things_do_I_sell & 001:
		menu_tabs.get_child(0).visible = false
	if not what_things_do_I_sell & 010:
		menu_tabs.get_child(1).visible = false
		menu_tabs.get_child(2).visible = false
		menu_tabs.get_child(3).visible = false
		menu_tabs.get_child(4).visible = false
	if not what_things_do_I_sell & 100:
		menu_tabs.get_child(5).visible = false
		
	for tab in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(tab)._setup(tab_icons[tab])
		
	for child in range(stock_container.get_child_count()):
		stock_container.get_child(child)._setup(tabs[child], shop_stock, shop_discount)
		if not stock_container.get_child(child).update_item_description.is_connected(_update_item_description):
			stock_container.get_child(child).update_item_description.connect(_update_item_description)

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

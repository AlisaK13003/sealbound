extends Node2D

class_name shop_controller

@export var shop_owner : Texture2D

@export var shop_stock: Array[shop_item]

@onready var shop_ui = $ShopInterface
@onready var item_selection = shop_ui.get_node("Item_Selection")
@onready var currency_display = shop_ui.get_node("HBoxContainer").get_node("Total_Currency")

var shop_item_scene = preload("res://assets/Resources/Shop_Stock_Node.tscn")

var can_open_shop : bool = false

func _ready():
	for item in shop_stock:
		var item_display = shop_item_scene.instantiate()
		item_selection.add_child(item_display)
		item_display.setup(item)
		item_display.item_bought.connect(item_purchased.bind(item))
		
func item_purchased(item):
	var thingy_name
	match item.item_type:
		1:
			thingy_name = item.item_thing.item_name
		2:
			thingy_name = item.equipment_thing.equipment_name
		4:
			thingy_name = item.weapon_thing.weapon_name
	print("You have just sold your soul: ", thingy_name)
	Global.money -= item.buy_price
	currency_display.text = str(Global.money)

func show_shop():
	currency_display.text = str(Global.money)

func _input(event):
	if event.is_action_pressed("Open Menu") and can_open_shop:
		shop_ui.visible = true
		show_shop()

func _on_area_2d_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = true

func _on_area_2d_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = false

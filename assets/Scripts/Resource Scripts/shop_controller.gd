extends Node2D

class_name shop_controller

@export var shop_stock: Array[custom_shop_item]

@onready var shop_ui = $CanvasLayer/ShopInterface
@onready var item_selection = shop_ui.get_node("Item_Selection")
@onready var currency_display = shop_ui.get_node("HBoxContainer").get_node("Total_Currency")

var shop_item_scene = preload("res://assets/Resources/Shop_Stock_Node.tscn")

var can_open_shop : bool = false
 
signal shop_populated

func _ready():
	Global.money = 1000
	currency_display.text = str(Global.money)
	for item in range(len(shop_stock)):
		var item_display = shop_item_scene.instantiate()
		item_selection.add_child(item_display)
		item_display.setup(shop_stock[item].item)

func show_shop():
	Global.is_in_menu = true
	currency_display.text = str(Global.money)
	shop_populated.emit()
	
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

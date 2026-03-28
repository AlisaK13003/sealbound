extends Node2D

class_name shop_controller

@export var shop_stock: Array[custom_shop_item]

@onready var shop_ui = $CanvasLayer/ShopInterface
@onready var item_selection = shop_ui.get_node("Item_Selection")
@onready var currency_display = shop_ui.get_node("HBoxContainer").get_node("Total_Currency")
@onready var purchase_confirmation_parent = shop_ui.get_node("Control")
@onready var selection_arrows = purchase_confirmation_parent.get_node("HBoxContainer2")
@onready var purchase_button = purchase_confirmation_parent.get_node("Panel2")
@onready var purchase_total_label = purchase_confirmation_parent.get_node("Purchase_Total")

var shop_item_scene = preload("res://assets/Resources/Shop_Stock_Node.tscn")

var can_open_shop : bool = false

var selected_item: int = -1

func _ready():
	Global.money = 1000
	currency_display.text = str(Global.money)
	for item in range(len(shop_stock)):
		var item_display = shop_item_scene.instantiate()
		item_selection.add_child(item_display)
		item_display.setup(shop_stock[item].item)
		item_display.item_bought.connect(item_selected.bind(item))
	selection_arrows.get_child(0).gui_input.connect(_on_left_selection_arrow_pressed)
	selection_arrows.get_child(2).gui_input.connect(_on_right_selection_arrow_pressed)
	purchase_button.gui_input.connect(_on_confirm_purchase)
	Global.purse_updated.connect(update_money_display)

func update_money_display():
	currency_display.text = str(Global.money)

func item_selected(item: int):
	if shop_stock[item].quantity > 0:
		purchase_confirmation_parent.visible = true
		selected_item = item
		reset_selection()
		item_selection.get_child(item).change_color(Color.BROWN)
		purchase_total_label.text = str(-1 * shop_stock[item].item.buy_price)
		
func reset_selection():
	for item in item_selection.get_children():
		item.change_color(Color.AQUAMARINE)
	selection_arrows.get_child(1).text = str(1)

func show_shop():
	currency_display.text = str(Global.money)

func _input(event):
	if event.is_action_pressed("Open Menu") and can_open_shop:
		shop_ui.visible = true
		show_shop()

func _on_left_selection_arrow_pressed(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		var label = selection_arrows.get_child(1)
		label.text = str(int(label.text) - 1)
		if int(label.text) == 0:
			if Global.money >= (shop_stock[selected_item].quantity * shop_stock[selected_item].item.buy_price):
				label.text = str(shop_stock[selected_item].quantity)
			else:
				label.text = str(clamp(floor(Global.money / shop_stock[selected_item].item.buy_price), 1, shop_stock[selected_item].quantity))
		purchase_total_label.text = str(-1 * int(label.text) * shop_stock[selected_item].item.buy_price)
	
func _on_right_selection_arrow_pressed(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		var label = selection_arrows.get_child(1)
		label.text = str(int(label.text) + 1)
		if int(label.text) > shop_stock[selected_item].quantity:
			label.text = str(1)
		purchase_total_label.text = str(-1 * int(label.text) * shop_stock[selected_item].item.buy_price)

func _on_confirm_purchase(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		var quantity_purchased = selection_arrows.get_child(1).text
		print("BUYING ", quantity_purchased, " of ", shop_stock[selected_item].item.item_name)
		var amount_spent = int(quantity_purchased) * shop_stock[selected_item].item.buy_price
		shop_stock[selected_item].quantity = shop_stock[selected_item].quantity - int(quantity_purchased)
		reset_selection()
		Global.spent_or_obtained_money(-1 * amount_spent)
		for x in range(int(quantity_purchased)):
			Global.add_to_first_open_slot(shop_stock[selected_item].item)
		if shop_stock[selected_item].quantity <= 0:
			item_selection.get_child(selected_item).item_out_of_stock()
		selection_arrows.get_child(1).text = str(1)
		purchase_confirmation_parent.visible = false
		selected_item = -1

func _on_area_2d_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = true

func _on_area_2d_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = false

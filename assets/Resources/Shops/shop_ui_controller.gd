extends Control

var can_scroll: bool
var selected_index = 0

var shop_stock: Array[custom_shop_item]

@onready var item_window = $Item_Selection

var start_range = 0
var end_range = 9
var selected_item: int = -1

@onready var currency_display = get_node("HBoxContainer").get_node("Total_Currency")

@onready var purchase_button = $Panel2/Purchase_Button
@onready var amount_toggle = $Panel2/Amount_Toggle
@onready var amount_total = $Panel2/Amount_Total
@onready var amount_to_buy = $Panel2/Amount_To_buy
@onready var cancel_button = $Panel2/Cancel_Button
@onready var purchase_confirmation_parent = $Panel2
@onready var selected_item_texture = $Panel2/Item_Texture
@onready var selected_item_name = $Panel2/Item_Name
@export var parent : Node2D
@onready var item_quantity = $Panel2/Item_Quantity
@onready var scroll_bar = $Panel/Scroll

func _ready():
	await parent.ready
	parent.shop_populated.connect(update_display.bind(0))
	shop_stock = parent.shop_stock
	
	purchase_button.gui_input.connect(_on_confirm_purchase)
	purchase_confirmation_parent.visible = false
	cancel_button.gui_input.connect(close_thing)
	for item in range(len(shop_stock)):
		item_window.get_child(item).item_bought.connect(item_selected.bind(item))
	
	amount_toggle.get_child(0).gui_input.connect(_on_left_selection_arrow_pressed)
	amount_toggle.get_child(1).gui_input.connect(_on_right_selection_arrow_pressed)		
		
	Global.purse_updated.connect(update_money_display)

func close_thing(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		await get_tree().create_timer(0.1).timeout
		purchase_confirmation_parent.visible = false
		reset_selection()

func _input(event):
	if can_scroll and purchase_confirmation_parent.visible == false:
		if event.is_action_pressed("Mouse Scroll Down"):
			update_display(1)
		if event.is_action_pressed("Mouse Scroll Up"):
			update_display(-1)
			
func _on_area_2d_mouse_entered():
	can_scroll = true

func _on_area_2d_mouse_exited():
	can_scroll = false
	
func update_display(change_range_by):
	var loop_bounds = item_window.get_child_count()
	if selected_index == 0:
		start_range = 0
		end_range = clamp(end_range, start_range + 9, loop_bounds)
	
	
	#if selected_index == end_range - 2 and change_range_by == 1:
		#start_range = clamp(start_range + change_range_by, 0, loop_bounds - 9)
		#end_range = clamp(end_range + change_range_by, start_range + 9, loop_bounds)
	#elif selected_index == start_range + 1 and change_range_by == -1:
		#start_range = clamp(start_range + change_range_by, 0, loop_bounds - 9)
		#end_range = clamp(end_range + change_range_by, start_range + 9, loop_bounds)
	start_range = clamp(start_range + change_range_by, 0, loop_bounds-9)
	end_range = clamp(end_range + change_range_by, start_range + 9, loop_bounds)
	selected_index = clamp(change_range_by + selected_index, 0, item_window.get_child_count())
	scroll_bar.value = clamp((item_window.get_child_count() * selected_index), 0, 100)

	for i in range(item_window.get_child_count()):
		if i >= start_range and i < end_range:
			item_window.get_child(i).visible = true
		else:
			item_window.get_child(i).visible = false

func _on_left_selection_arrow_pressed(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		amount_to_buy.text = str(int(amount_to_buy.text) - 1) + "x"
		if int(amount_to_buy.text) == 0:
			if Global.money >= (shop_stock[selected_item].quantity * shop_stock[selected_item].item.buy_price):
				amount_to_buy.text = str(shop_stock[selected_item].quantity) + "x"
			else:
				amount_to_buy.text = str(clamp(floor(Global.money / shop_stock[selected_item].item.buy_price), 1, shop_stock[selected_item].quantity)) + "x"
		amount_total.text = str(int(amount_to_buy.text) * shop_stock[selected_item].item.buy_price) + "g"
	
func _on_right_selection_arrow_pressed(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		amount_to_buy.text = str(int(amount_to_buy.text) + 1) + "x"
		if int(amount_to_buy.text) > shop_stock[selected_item].quantity:
			amount_to_buy.text = str(1) + "x"
		amount_total.text = str(int(amount_to_buy.text) * shop_stock[selected_item].item.buy_price) + "g"

func _on_confirm_purchase(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		await get_tree().create_timer(0.1).timeout
		var quantity_purchased = amount_to_buy.text
		print("BUYING ", quantity_purchased, " of ", shop_stock[selected_item].item.item_name)
		var amount_spent = int(quantity_purchased) * shop_stock[selected_item].item.buy_price
		shop_stock[selected_item].quantity = shop_stock[selected_item].quantity - int(quantity_purchased)
		reset_selection()
		Global.spent_or_obtained_money(-1 * amount_spent)
		for x in range(int(quantity_purchased)):
			shop_stock[selected_index].item.amount_held = quantity_purchased
			Global.add_to_first_open_slot(shop_stock[selected_item].item)
		if shop_stock[selected_item].quantity <= 0:
			item_window.get_child(selected_item).item_out_of_stock()
		amount_to_buy.text = str(1)
		purchase_confirmation_parent.visible = false
		selected_item = -1

func update_money_display():
	currency_display.text = str(Global.money)

func item_selected(item: int):
	if shop_stock[item].quantity > 0 and purchase_confirmation_parent.visible == false:
		selected_item_name.text = shop_stock[item].item.item_name
		selected_item_texture.texture = shop_stock[item].item.item_texture
		purchase_confirmation_parent.visible = true
		selected_item = item
		reset_selection()
		amount_total.text = str(shop_stock[item].item.buy_price) + "g"
		amount_to_buy.text = str(1) + "x"
		item_quantity.text = "Amount Left: " + str(shop_stock[item].quantity) + "x"
		
func reset_selection():
	amount_to_buy.text = str(1)

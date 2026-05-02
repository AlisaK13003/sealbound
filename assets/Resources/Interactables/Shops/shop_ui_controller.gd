extends Control

var can_scroll: bool
var selected_index = 0

var shop_stock: Array[custom_shop_items]

@onready var item_window = $"Buy Menu/Item_Selection"

var start_range = 0
var end_range = 9
var selected_item: int = -1

@onready var entire_buy_menu = $"Buy Menu"
@onready var currency_display = $"Money Counter/HBoxContainer/Total_Currency"
@onready var purchase_button = $"Buy _ Sell Confirmation/Panel2/Purchase_Button"
@onready var amount_toggle = $"Buy _ Sell Confirmation/Panel2/Amount_Toggle"
@onready var amount_total = $"Buy _ Sell Confirmation/Panel2/Amount_Total"
@onready var amount_to_buy = $"Buy _ Sell Confirmation/Panel2/Amount_To_buy"
@onready var purchase_confirmation_parent = $"Buy _ Sell Confirmation"
@onready var selected_item_texture = $"Buy _ Sell Confirmation/Panel2/Item_Texture"
@onready var selected_item_name = $"Buy _ Sell Confirmation/Panel2/Item_Name"
@export var parent : Node2D
@onready var item_quantity = $"Buy _ Sell Confirmation/Panel2/Item_Quantity"
@onready var scroll_bar = $"Buy Menu/Panel/Scroll"
@onready var cancel_button = $"Buy _ Sell Confirmation/Panel2/Cancel_Button"
@onready var sell_menu = $SellMenu
@onready var inventory_item_container = sell_menu.get_node("Panel/GridContainer")

signal open_sell_menu(item_to_sell)

var contemplating_to_sell: inventory_items
var item_slot_to_sell: int

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
	
	for child in range(inventory_item_container.get_child_count()):
		inventory_item_container.get_child(child)._setup(child, self)
		inventory_item_container.get_child(child).change_color(parent.shop_sell_node_color)
	Global.inventory_updated.connect(update_inventory_slot)
	if parent.test_sell_menu:
		sell_menu.visible = true
		entire_buy_menu.visible = false
	else:
		sell_menu.visible = false
		entire_buy_menu.visible = true
	open_sell_menu.connect(open_sell_menu_action)

func open_sell_menu_action(selected_item2: inventory_items, slot_to_sell):
	contemplating_to_sell = selected_item2
	if selected_item2 != null:
		item_slot_to_sell = slot_to_sell
		purchase_confirmation_parent.visible = true
		purchase_button.get_child(0).text = "sell!"
		amount_to_buy.text = str(selected_item2.amount_held) + "x"
		
		selected_item_name.text = contemplating_to_sell.item_name
		selected_item_texture.texture = contemplating_to_sell.item_texture
		purchase_confirmation_parent.visible = true
		amount_total.text = str(contemplating_to_sell.sell_price * contemplating_to_sell.amount_held)  + "g"
		item_quantity.text = ""

func close_thing(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		await get_tree().create_timer(0.1).timeout
		purchase_confirmation_parent.visible = false

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
		print("LEFT")
		if not sell_menu.visible:
			amount_to_buy.text = str(int(amount_to_buy.text) - 1) + "x"
			if int(amount_to_buy.text) == 0:
				if Global.money >= (shop_stock[selected_item].quantity * shop_stock[selected_item].item.buy_price):
					amount_to_buy.text = str(shop_stock[selected_item].quantity) + "x"
				else:
					amount_to_buy.text = str(clamp(floor(Global.money / shop_stock[selected_item].item.buy_price), 1, shop_stock[selected_item].quantity)) + "x"
			amount_total.text = str(int(amount_to_buy.text) * shop_stock[selected_item].item.buy_price) + "g"
		else:
			amount_to_buy.text = str(int(amount_to_buy.text) - 1) + "x"
			if int(amount_to_buy.text) == 0:
				amount_to_buy.text = str(contemplating_to_sell.amount_held) + "x"
			amount_total.text = str(int(amount_to_buy.text) * contemplating_to_sell.sell_price) + "g"
	
func _on_right_selection_arrow_pressed(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		print("RIGHT")
		if not sell_menu.visible:
			amount_to_buy.text = str(int(amount_to_buy.text) + 1) + "x"
			if int(amount_to_buy.text) > shop_stock[selected_item].quantity:
				amount_to_buy.text = str(1) + "x"
			amount_total.text = str(int(amount_to_buy.text) * shop_stock[selected_item].item.buy_price) + "g"
		else:
			amount_to_buy.text = str(int(amount_to_buy.text) + 1) + "x"
			if int(amount_to_buy.text) > contemplating_to_sell.amount_held:
				amount_to_buy.text = str(1) + "x"
			amount_total.text = str(int(amount_to_buy.text) * contemplating_to_sell.sell_price) + "g"

func _on_confirm_purchase(event):
	if event.is_action_pressed("Mouse_Left_Click"):
		if not sell_menu.visible:
			await get_tree().create_timer(0.1).timeout
			var quantity_purchased = amount_to_buy.text
			print("BUYING ", quantity_purchased, " of ", shop_stock[selected_item].item.item_name)
			var amount_spent = int(quantity_purchased) * shop_stock[selected_item].item.buy_price
			shop_stock[selected_item].quantity = shop_stock[selected_item].quantity - int(quantity_purchased)
			Global.spent_or_obtained_money(-1 * amount_spent)
			var bought_item = shop_stock[selected_item].item
			bought_item.amount_held = int(quantity_purchased)
			Global.add_to_first_open_slot(bought_item)
			if shop_stock[selected_item].quantity <= 0:
				item_window.get_child(selected_item).item_out_of_stock()
			amount_to_buy.text = str(1) + "x"
			purchase_confirmation_parent.visible = false
			selected_item = -1
		else:
			await get_tree().create_timer(0.1).timeout
			var quantity_purchased = amount_to_buy.text
			print("Selling ", quantity_purchased, " of ", contemplating_to_sell.item_name)
			var amount_spent = int(quantity_purchased) * contemplating_to_sell.sell_price
			Global.spent_or_obtained_money(int(quantity_purchased) * contemplating_to_sell.sell_price)
			Global.remove_from_inventory_n_times(item_slot_to_sell, int(quantity_purchased))
			amount_to_buy.text = str(1) + "x"
			purchase_confirmation_parent.visible = false

func update_money_display():
	currency_display.text = str(Global.money)

func item_selected(item: int):
	if shop_stock[item].quantity > 0 and purchase_confirmation_parent.visible == false:
		selected_item_name.text = shop_stock[item].item.item_name
		selected_item_texture.texture = shop_stock[item].item.item_texture
		purchase_confirmation_parent.visible = true
		selected_item = item
		amount_total.text = str(shop_stock[item].item.buy_price) + "g"
		amount_to_buy.text = str(1) + "x"
		item_quantity.text = "Amount Left: " + str(shop_stock[item].quantity) + "x"

func update_inventory_slot(slot_to_update):
	var child_to_update = inventory_item_container.get_child(slot_to_update)
	if child_to_update.held_item == Global.village_inventory[slot_to_update]:
		child_to_update.held_item = null
		child_to_update.holding_item = false
	if Global.village_inventory[slot_to_update] == null:
		child_to_update.empty_cell()
	else:
		child_to_update.update_held_item(Global.village_inventory[slot_to_update])
 
func _exit_shop():
	self.visible = false
	purchase_confirmation_parent.visible = false
	Global.is_in_menu = false

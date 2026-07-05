extends Node2D

class_name shop_controller

@export var shop_stock: Array[custom_shop_items]

@onready var shop_ui = $CanvasLayer/ShopInterface
@onready var item_selection = shop_ui.get_node("Buy Menu/Item_Selection")
@onready var currency_display = shop_ui.get_node("Money Counter/HBoxContainer/Total_Currency")
@onready var shop_owner_portrait_rect: TextureRect = shop_ui.get_node_or_null("Buy Menu/Panel3/TextureRect")
@onready var shop_name_label: Label = shop_ui.get_node_or_null("Buy Menu/Panel3/Label")
@onready var shop_owner_name_label: Label = shop_ui.get_node_or_null("Buy Menu/Panel3/Label2")

var shop_item_scene = preload("res://assets/Resources/Shop_Stock_Node.tscn")

var can_open_shop : bool = false
 
signal shop_populated

@export var shop_sell_node_color: Color

@export var test_sell_menu : bool
@export var shop_owner_portrait: Texture2D
@export var shop_name: String = ""
@export var shop_owner_name: String = ""

func _ready():
	self.visible = false
	shop_ui.visible = false
	can_open_shop = false
	currency_display.text = str(GlobalCombatInformation.currency_held)
	update_shop_details()
	for item in range(len(shop_stock)):
		var item_display = shop_item_scene.instantiate()
		item_selection.add_child(item_display)
		item_display.setup(shop_stock[item].item)

func show_shop():
	process_mode = Node.PROCESS_MODE_ALWAYS
	shop_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	if shop_ui.get_parent() != null:
		shop_ui.get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	self.visible = true
	shop_ui.visible = true
	Global.is_in_menu = true
	get_tree().paused = true
	currency_display.text = str(GlobalCombatInformation.currency_held)
	update_shop_details()
	shop_populated.emit()

func update_shop_details() -> void:
	if shop_owner_portrait_rect != null and shop_owner_portrait != null:
		shop_owner_portrait_rect.texture = shop_owner_portrait
	if shop_name_label != null and not shop_name.is_empty():
		shop_name_label.text = shop_name
	if shop_owner_name_label != null and not shop_owner_name.is_empty():
		shop_owner_name_label.text = shop_owner_name
	
func _input(event):
	if event.is_action_pressed("confirm") and can_open_shop:
		show_shop()

func _on_area_2d_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = true

func _on_area_2d_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		can_open_shop = false

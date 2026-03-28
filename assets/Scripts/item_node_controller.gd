extends Control

@onready var clickable_area = $Area2D
@onready var item_sprite = $"Sprite-Name/Item_Sprite2"
@onready var item_name_label = $"Sprite-Name/Item_Name"
@onready var item_cost_label = $"Cost-Currency/Cost"
@onready var attached_panel = $Panel
@onready var big_red_x = $"Out Of Stock"

var stylebox : StyleBoxFlat

signal item_bought()

var what_item_am_i

var out_of_stock: bool = false

func setup(thingy: inventory_items):
	what_item_am_i = thingy
	item_name_label.text = thingy.item_name
	item_cost_label.text = str(thingy.buy_price)
	item_sprite.texture = thingy.item_texture
	
func _ready():
	clickable_area.input_event.connect(_on_input_event)
	
	var current_style = attached_panel.get_theme_stylebox("panel")
	
	if stylebox is StyleBoxFlat:
		stylebox = current_style.duplicate()
	else:
		stylebox = StyleBoxFlat.new()
		
	attached_panel.add_theme_stylebox_override("panel", stylebox)

func item_out_of_stock():
	out_of_stock = true
	big_red_x.visible = true

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if (Global.money - what_item_am_i.buy_price) >= 0 and not out_of_stock:
					item_bought.emit()
					
func change_color(new_color):
	if not is_node_ready():
		await ready
	
	stylebox.bg_color = new_color

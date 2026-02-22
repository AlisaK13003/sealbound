extends Control

@onready var clickable_area = $Area2D
@onready var item_sprite = $"Sprite-Name/Item_Sprite2"
@onready var item_name_label = $"Sprite-Name/Item_Name"
@onready var item_cost_label = $"Cost-Currency/Cost"

signal item_bought()

var what_item_am_i

func setup(thingy: shop_item):
	what_item_am_i = thingy
	match thingy.item_type:
		#Item
		1:
			item_sprite = thingy.item_thing.item_sprite
			item_name_label.text = thingy.item_thing.item_name
		# Equipment
		2:
			item_name_label.text = thingy.equipment_thing.equipment_name
		# Sword
		4:
			item_name_label.text = thingy.weapon_thing.weapon_name
	item_cost_label.text = str(thingy.buy_price)
func _ready():
	clickable_area.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if (Global.money - what_item_am_i.buy_price) >= 0:
					item_bought.emit()

extends Control

var stored_item

var thing_texture
var thing_name
var thing_price
var thing_in_stock
var thing_in_inventory

signal node_hovered
signal node_pressed

func _setup(thing, discount):
	stored_item = thing
	var label_name = ""
	var label_texture = null
	var label_price = ""
	if thing is Items:
		label_name = thing.item_name
		label_texture = thing.item_sprite
	elif thing is equipment:
		label_name = thing.equipment_name
		label_texture = thing.equipment_sprite
	elif thing is weapon:
		label_name = thing.weapon_name
		label_texture = thing.weapon_texture
			
	label_price = str(thing.buy_price)
	if discount != 0.0:
		$Discount/Label.text = "-" + str(int(discount * 100)) + "%"
		$Discount.visible = true
		label_price = str(int(float(label_price) - (float(label_price) * discount)))
	
	thing_texture = $HBoxContainer/thing_texture
	thing_name = $HBoxContainer/thing_name
	thing_price = $HBoxContainer/thing_price
	thing_in_stock = $HBoxContainer/thing_in_stock
	thing_in_inventory = $HBoxContainer/thing_in_inventory
	
	thing_texture.texture = label_texture if label_texture != null else load("res://assets/Equipment/Equipment Sprites/Rusty Sword.png")
	thing_name.text = label_name if label_name != "" else "Training Sword"
	thing_price.text = label_price if label_price != "" else "50"
	thing_in_stock.text = str(thing.shop_quantity)
	thing_in_inventory.text = str(GlobalCombatInformation.search_for_thing(thing))

func _ready():
	GlobalCombatInformation.equipment_added.connect(update_everything)
	GlobalCombatInformation.check_quest_progress.connect(update_everything)

func highlight(highlight):
	if highlight:
		$Control/Panel.modulate = Color.BEIGE
		$Control/Panel.modulate.a = 255
	else:
		$Control/Panel.modulate = Color.WHITE
		$Control/Panel.modulate.a = 0

func update_stock_count():
	thing_in_stock.text = str(stored_item.shop_quantity)

func update_everything():
	#thing_texture.texture = label_texture if label_texture != null else load("res://assets/Equipment/Equipment Sprites/Rusty Sword.png")
	#thing_name.text = label_name if label_name != "" else "Training Sword"
	#thing_price.text = label_price if label_price != "" else "50"
	thing_in_stock.text = str(stored_item.shop_quantity)
	thing_in_inventory.text = str(GlobalCombatInformation.search_for_thing(stored_item))
	if stored_item.shop_quantity <= 0:
		disable()

var disabled = false
func disable():
	$Control/Panel.modulate = Color.PALE_VIOLET_RED
	self.modulate = Color.PALE_VIOLET_RED
	disabled = true

func was_hovered():
	if not disabled:
		node_hovered.emit(stored_item, get_index())

func _on_gui_input(event):
	if disabled:
		return
	node_hovered.emit(stored_item, get_index())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			node_pressed.emit(stored_item)

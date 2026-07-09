extends Control

@onready var stock_container: GridContainer = $Scroll/Stock_Container

var stock_node_path = "res://assets/Resources/Interactables/Shops/Shop_Stock_Node.tscn"

var type

var container_start_position: Vector2

var disable_selection: bool = false

var discount: float

func _ready():
	container_start_position = stock_container.position
	Global.is_paused = true
	visibility_changed.connect(_visibility_changed)
	$Confirmation/OptionCycle.option_changed.connect(update_projected_price)
	GlobalCombatInformation.check_quest_progress.connect(_reset)
	GlobalCombatInformation.equipment_added.connect(_reset)

func wipe_clean():
	for child in stock_container.get_children():
		stock_container.remove_child(child)
		child.queue_free()
		
func _reset():
	for child in stock_container.get_children():
		stock_container.remove_child(child)
		child.queue_free()
	
	var string_type
	match type:
		0:
			string_type = "Weapons"
		1:
			string_type = "Helmets"
		2:
			string_type = "Chestplates"
		3:
			string_type = "Boots"
		4:
			string_type = "Charms"
		5:
			string_type = "Items"
		
	_setup(string_type, held_stock, discount)

func _visibility_changed():
	if visible == false:
		return
	update_item_description.emit(stock_container.get_child(0).stored_item)

var held_stock
func _setup(stock_type, list_of_stock, discount):
	self.discount = discount
	held_stock = list_of_stock
	stock_container = $Scroll/Stock_Container
	match stock_type:
		"Weapons":
			type = 0
		"Helmets":
			type = 1
		"Chestplates":
			type = 2
		"Boots":
			type = 3
		"Charms":
			type = 4
		"Items":
			type = 5
		_:
			type = 0
	$HBoxContainer/Label.text = stock_type
	for thing in list_of_stock:
		if thing is Items and type == 5:
			_add_node(thing)
		elif thing is equipment and (type != 5 and type != 0):
			match type:
				1:
					if thing.equipment_type == 0:
						_add_node(thing)
				2:
					if thing.equipment_type == 1:
						_add_node(thing)
				3:
					if thing.equipment_type == 2:
						_add_node(thing)
				4:
					if thing.equipment_type == 3:
						_add_node(thing)
			continue
		elif thing is weapon and type == 0:
			_add_node(thing)
			continue
	
	$Scroll._setup()


func _update_stock():
	pass
	
var count = 0
func _add_node(node_to_add):
	var already_exists: int = -1
	for node in stock_container.get_children():
		if node.stored_item != null:
			if node.stored_item is Items and node.stored_item.item_name == node_to_add.item_name:
				already_exists = node.get_index()
				break
			elif node.stored_item is equipment and node.stored_item.equipment_name == node_to_add.equipment_name:
				already_exists = node.get_index()
				break
			elif node.stored_item is weapon and node.stored_item.weapon_name == node_to_add.weapon_name:
				already_exists = node.get_index()
				break
	if already_exists != -1:
		stock_container.get_child(already_exists).stored_item.shop_quantity += 1
		stock_container.get_child(already_exists).update_stock_count()
		return
	
	var new_node = load(stock_node_path)
	var new_node_instance = new_node.instantiate()
	
	new_node_instance._setup(node_to_add, discount)
	new_node_instance.node_hovered.connect(thing_hovered)
	new_node_instance.node_pressed.connect(node_pressed)
	stock_container.add_child(new_node_instance)
	
	if node_to_add.buy_price > GlobalCombatInformation.currency_held or node_to_add.shop_quantity == 0:
		new_node_instance.disable()

var current_options
func node_pressed(item):
	$Confirmation.visible = true
	if item is weapon:
		$Confirmation/TextureRect.texture = item.weapon_texture
		$Confirmation/Label2.text = item.weapon_name
	elif item is equipment:
		$Confirmation/TextureRect.texture = item.equipment_sprite
		$Confirmation/Label2.text = item.equipment_name
	elif item is Items:
		$Confirmation/TextureRect.texture = item.item_sprite
		$Confirmation/Label2.text = item.item_name
	
	$Scroll.disable()
	disable_selection = true
	
	var options = []
	var adjusted_price = int(float(item.buy_price) - (float(item.buy_price) * discount))
	
	for i in range(item.shop_quantity):
		if (adjusted_price * (i + 1)) <= GlobalCombatInformation.currency_held:
			options.append(str(i + 1))
		else:
			break
			
	$Confirmation/Label.text = str(adjusted_price)
	$Confirmation/OptionCycle._setup(0, options)
	await_purchase(item)

func update_projected_price(options, cur_option):
	$Confirmation/Label.text = str(int(options[cur_option]) * (int(float(perusing_item.buy_price) - float(perusing_item.buy_price) * discount)))

var perusing_item
signal confirmation
func await_purchase(item):
	Global.cant_leave_menu = true
	perusing_item = item
	var descision = await confirmation
	Global.cant_leave_menu = false
	if descision:
		var amount_purchased = int($Confirmation/OptionCycle/HBoxContainer/Label.text)
		
		var adjusted_price = int(float(item.buy_price) - (float(item.buy_price) * discount)) * amount_purchased

		GlobalCombatInformation.update_currency(-1 * adjusted_price)
		item.shop_quantity -= amount_purchased
		for i in range(amount_purchased):
			if item is equipment or item is weapon:
				GlobalCombatInformation.equipment_added_to_list(item, true if item is weapon else false)
			elif item is Items:
				GlobalCombatInformation.add_item(item)


func cancel_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if $Confirmation.visible:
				$Confirmation.visible = false
				$Scroll.enable()
				disable_selection = false
				confirmation.emit(false)

func purchase_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if $Confirmation.visible:
				$Confirmation.visible = false
				$Scroll.enable()
				disable_selection = false
				confirmation.emit(true)

signal update_item_description
func thing_hovered(which_thing, child_num):
	if disable_selection:
		return
	$Scroll.current_item = child_num
	$Scroll.update_selected_item()
	
	update_item_description.emit(which_thing)

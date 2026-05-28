extends Control

@export var node_to_instantiate: String
@onready var item_container = $VBoxContainer
@onready var menu_name = $Menu_Name
@onready var description = $Description_Label
var p_ref

func _setup(items_to_setup, parent_reference, m_name):
	await clear_children()
	p_ref = parent_reference
	menu_name.text = m_name
	var list_item_scene = load(node_to_instantiate)

	for item in range(items_to_setup.size()):
		var new_item = list_item_scene.instantiate()
		item_container.add_child(new_item)
		await new_item._setup(items_to_setup[item], item, self)

func clear_children():
	for child in item_container.get_children():
		item_container.remove_child(child)
		child.queue_free()

func update_description(new_description):
	description.text = new_description

func unselect_all():
	for child in item_container.get_children():
		child.unselect()

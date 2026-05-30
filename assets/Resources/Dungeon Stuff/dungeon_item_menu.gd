extends Control

@export var node_to_instantiate: String
@onready var item_container = $VBoxContainer
@onready var menu_name = $Menu_Name
@onready var description = $Description_Label
var p_ref

var which_child_is_selected = 0

func _setup(items_to_setup, parent_reference, m_name):
	await clear_children()
	p_ref = parent_reference
	menu_name.text = m_name
	var list_item_scene = load(node_to_instantiate)

	for item in range(items_to_setup.size()):
		var new_item = list_item_scene.instantiate()
		item_container.add_child(new_item)
		await new_item._setup(items_to_setup[item], item, self)
		if item == 0:
			new_item.select()

func clear_children():
	for child in item_container.get_children():
		item_container.remove_child(child)
		child.queue_free()

func update_selected_child(what_child_got_selected):
	which_child_is_selected = what_child_got_selected

func update_description(new_description):
	description.text = new_description

func update_selection(up_or_down):
	var child_to_check = item_container.get_child(which_child_is_selected)
	if child_to_check.can_be_unselected:
		unselect_all()
		var updated_index = (which_child_is_selected + up_or_down)
		var child_count = item_container.get_child_count() - 1
		var newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
		item_container.get_child(newly_selected_child).select()

func selection_confirmed():
	item_container.get_child(which_child_is_selected).selection_confirmed()

func execute_selection():
	item_container.get_child(which_child_is_selected).execute_selection()

func unselect_all():
	for child in item_container.get_children():
		child.unselect()

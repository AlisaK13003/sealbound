extends Control


@onready var item_container = $GridContainer
@export var number_of_columns : int = 2
var parent_reference

func _ready():
	item_container.columns = number_of_columns

func setup(item_list: Array[Items], parent_ref):
	parent_reference = parent_ref
	update_item_list(item_list)

func update_item_list(item_list: Array[Items]):
	for item in range(item_container.get_child_count()):
		if item > item_list.size() - 1:
			item_container.get_child(item).visible = false
			continue
		item_container.get_child(item).setup(item_list[item].duplicate(), item, parent_reference)

func _on_item_selected(event, extra_arg_0):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print(item_container.get_child(extra_arg_0).item_name)

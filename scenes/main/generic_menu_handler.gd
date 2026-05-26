extends Control

@onready var menu_tabs : GridContainer= $Menu_Tabs
@export var menu_self : Control

@export var v_separation: int = 20
@export var h_separation: int = 20
@export var column_count: int = 1

@export var child_offset = 2

func _ready():
	menu_tabs.add_theme_constant_override("h_separation", h_separation)
	menu_tabs.add_theme_constant_override("v_separation", v_separation)
	menu_tabs.columns = column_count
	for name_ in range(menu_tabs.get_child_count()):
		if name_ == 0:
			menu_tabs.get_child(0).get_child(0).color = Color.YELLOW
			menu_tabs.get_child(name_).get_child(1).text = menu_self.get_child(name_ + child_offset).name
			menu_tabs.get_child(name_).visible = true
			menu_self.get_child(name_ + child_offset).visible = true
		else:
			if name_ < menu_self.get_child_count() - child_offset:
				menu_tabs.get_child(name_).get_child(1).text = menu_self.get_child(name_ + child_offset).name
				menu_tabs.get_child(name_).visible = true
				menu_self.get_child(name_ + child_offset).visible = false

			else:
				menu_tabs.get_child(name_).visible = false

func _swap_menu_tabs(extra_arg_0):
	for child in menu_tabs.get_children():
		if child.get_index() >= menu_self.get_child_count() - child_offset:
			continue
		if child.get_index() == extra_arg_0:
			child.get_child(0).color = Color.YELLOW
			menu_self.get_child(child.get_index() + child_offset).visible = true
			print("SWAPPING TO TAB: ", extra_arg_0)
		else:
			child.get_child(0).color = Color.WHITE
			menu_self.get_child(child.get_index() + child_offset).visible = false

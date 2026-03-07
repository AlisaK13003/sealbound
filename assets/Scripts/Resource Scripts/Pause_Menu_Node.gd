@tool

extends Control

class_name pause_menu_option

@onready var mouse_spot = $Area2D
@onready var option_name = $Panel/Label
@onready var attached_panel = $Panel

@export var selection_name : String
var stylebox : StyleBoxFlat

signal option_selected(selected_option)
signal option_hovered(selected_option)

func _ready():
	option_name.text = selection_name
	
	var current_style = attached_panel.get_theme_stylebox("panel")
	
	if stylebox is StyleBoxFlat:
		stylebox = current_style.duplicate()
	else:
		stylebox = StyleBoxFlat.new()
		
	attached_panel.add_theme_stylebox_override("panel", stylebox)

func change_color(new_color):
	if not is_node_ready():
		await ready
	
	stylebox.bg_color = new_color

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			option_selected.emit(selection_name)

func _on_area_2d_mouse_entered():
	option_hovered.emit(selection_name)

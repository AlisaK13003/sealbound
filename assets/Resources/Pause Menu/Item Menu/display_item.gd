extends Control

@export var item_name: Label
@export var item_sprite: TextureRect
@onready var attached_panel = $Panel
var stylebox : StyleBoxFlat

var what_am_i

signal item_clicked(current_item)

func _ready():
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

func setup(thing):
	if thing is Items:
		item_name.text = thing.item_name
		item_sprite.texture = thing.item_sprite
		what_am_i = thing
	elif thing is equipment:
		item_name.text = thing.equipment_name
		item_sprite.texture = null
		what_am_i = thing
	elif thing is weapon:
		item_name.text = thing.weapon_name
		item_sprite.texture = null
		what_am_i = thing
			
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_action_pressed("Left Mouse"):
			item_clicked.emit(what_am_i)

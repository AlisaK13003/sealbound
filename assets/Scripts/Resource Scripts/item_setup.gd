extends Control

@onready var item_sprite = $TextureRect
@onready var mouse_area = $Area2D
var held_item: Items
var where_is_item : int
var is_dragging : bool = false
var damage_or_heal : bool
var initial_position : Vector2

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position()
		global_position.x -= 20
		global_position.y -= 20

func setup(item: Items, index):
	where_is_item = index
	initial_position = self.global_position
	initial_position.x += (where_is_item * 50)
	held_item = item

	item_sprite.texture = item.item_sprite
	mouse_area.input_event.connect(on_mouse_enter.bind())
	damage_or_heal = item.does_what
	
func on_mouse_enter(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		is_dragging = true
		
func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed:
		if is_dragging:
			global_position = initial_position
			is_dragging = false

extends Area3D

@onready var subviewport = $"../SubViewport"
@onready var sprite = $".."

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouse:
		
		var local_pos = sprite.to_local(position)
		
		var sprite_size = sprite.texture.get_size() * sprite.pixel_size
		
		var percent_x = (local_pos.x / sprite_size.x) + 0.5
		var percent_y = 0.5 - (local_pos.y / sprite_size.y)
		
		var viewport_event = event.duplicate()
		
		viewport_event.position = Vector2(percent_x * subviewport.size.x, percent_y * subviewport.size.y)
		viewport_event.global_position = viewport_event.position
		
		subviewport.push_input(viewport_event)

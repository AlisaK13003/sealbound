extends Area3D

@onready var subviewport = $"../SubViewport"
@onready var sprite = $".."

func _input_event(camera, event, position, normal, shape_idx):
	# We only care about mouse events (clicks and movement/hovering)
	if event is InputEventMouse:
		
		# 1. Get where the mouse hit in 3D, relative to the Sprite's center
		var local_pos = sprite.to_local(position)
		
		# 2. Calculate the physical size of the Sprite3D
		# (Texture pixel dimensions multiplied by the Sprite3D's pixel_size scale)
		var sprite_size = sprite.texture.get_size() * sprite.pixel_size
		
		# 3. Convert that 3D hit to a percentage (0.0 to 1.0) across the sprite
		var percent_x = (local_pos.x / sprite_size.x) + 0.5
		var percent_y = 0.5 - (local_pos.y / sprite_size.y) # Invert Y because 2D goes down, 3D goes up
		
		# 4. Duplicate the event so we don't accidentally mess up the game window's mouse
		var viewport_event = event.duplicate()
		
		# 5. Apply the correct SubViewport coordinates
		viewport_event.position = Vector2(percent_x * subviewport.size.x, percent_y * subviewport.size.y)
		viewport_event.global_position = viewport_event.position
		
		# 6. Push the corrected event into the SubViewport!
		subviewport.push_input(viewport_event)

extends Line2D

var curve = Curve2D.new()


func _process(delta):
	var start_pos = Vector2.ZERO
	var target_pos = get_local_mouse_position()
	
	var mouse_angle = target_pos.angle() 
	
	var distance = start_pos.distance_to(target_pos)
	var control_strength = distance * 0.5
	
	var start_out = Vector2.from_angle(mouse_angle - deg_to_rad(45)) * control_strength
	
	var end_in = Vector2.from_angle(mouse_angle + deg_to_rad(180)) * control_strength

	curve.clear_points()
	curve.add_point(start_pos, Vector2.ZERO, start_out)
	curve.add_point(target_pos, end_in, Vector2.ZERO)
	
	points = curve.get_baked_points()
	
	$Sprite2D.position = target_pos
	$Sprite2D.rotation = (target_pos - (target_pos + end_in)).angle()

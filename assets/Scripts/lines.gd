extends Line2D

# We create the Curve2D resource in memory
var curve = Curve2D.new()


func _process(delta):
	var start_pos = Vector2.ZERO
	var target_pos = get_local_mouse_position()
	
	# 1. Get the angle from the card to the mouse
	var mouse_angle = target_pos.angle() 
	
	var distance = start_pos.distance_to(target_pos)
	var control_strength = distance * 0.5
	
	# 2. To create a curve, the start tangent shouldn't point DIRECTLY at the mouse.
	# If it points directly at the mouse, the line will be straight.
	# We rotate it slightly (e.g., -45 degrees) so it "swings" out before heading to the target.
	var start_out = Vector2.from_angle(mouse_angle - deg_to_rad(45)) * control_strength
	
	# 3. The end tangent comes "in" from the opposite side to meet the mouse
	var end_in = Vector2.from_angle(mouse_angle + deg_to_rad(180)) * control_strength

	curve.clear_points()
	curve.add_point(start_pos, Vector2.ZERO, start_out)
	curve.add_point(target_pos, end_in, Vector2.ZERO)
	
	points = curve.get_baked_points()
	
	$Sprite2D.position = target_pos
	$Sprite2D.rotation = (target_pos - (target_pos + end_in)).angle()

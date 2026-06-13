extends Control

func _ready():
	drop_and_swing_in()

func drop_and_swing_in():
	# 1. Setup Pivot & starting position (hidden above the screen, tilted left)
	pivot_offset = Vector2(size.x / 2, 0)
	position.y = -size.y
	rotation_degrees = -35.0
	
	var target_y = 200.0 # Where you want the scroll to stop
	
	# 2. Tween the position (drops down in 0.6 seconds)
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position:y", target_y, 0.6)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 3. Tween the rotation (a sequence of smaller and smaller swings)
	var rot_tween = create_tween()
	
	# Swing 1: Swing far to the right as it falls
	rot_tween.tween_property(self, "rotation_degrees", 20.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	# Swing 2: Swing back to the left (but less)
	rot_tween.tween_property(self, "rotation_degrees", -10.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Swing 3: Swing slightly to the right
	rot_tween.tween_property(self, "rotation_degrees", 4.0, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Swing 4: Settle perfectly at 0
	rot_tween.tween_property(self, "rotation_degrees", 0.0, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

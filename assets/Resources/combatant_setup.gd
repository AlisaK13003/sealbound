extends Control

@onready var combatant_name = $Label
@onready var combatant_sprite = $Sprite2D
@onready var health_bar = $TextureProgressBar
@onready var interactable_area = $Area2D

var stored_combatant : generic_combatants


func setup(combatant : generic_combatants):
	stored_combatant = combatant
	combatant_name.text = combatant.combatant_name
	combatant_sprite.texture = combatant.combatant_sprite
	health_bar.max_value = combatant.combatant_stats.max_health
	health_bar.value = combatant.combatant_stats.health
	if combatant.is_combatant_enemy:
		combatant_sprite.flip_h = false
	combatant.combatant_stats.health_changed.connect(update_health)
	create_collision_from_sprite()
	interactable_area.input_event.connect(do_nothing)
	
func do_nothing(viewport, event, shape_idx):
	if event is InputEventMouseButton and stored_combatant.is_combatant_enemy:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("HIII")
	
func update_health(change_health_value):
	health_bar.value = change_health_value
	if health_bar.value == 0:
		on_death()

func do_basic_attack():
	return (stored_combatant.combatant_stats.attack)

func on_death():
	self.visible = false

func create_collision_from_sprite():
	# 1. Clear any existing collision shapes to avoid duplicates
	for child in get_children():
		if child is CollisionPolygon2D:
			child.queue_free()

	# 2. Setup BitMap
	var texture = combatant_sprite.texture
	var image = texture.get_image()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# 3. Generate Polygons
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()), 2.0)
	
	# 4. Create the CollisionPolygon2D nodes
	for poly_points in polygons:
		var collision_poly = CollisionPolygon2D.new()
		collision_poly.polygon = poly_points
		
		# 5. Handle Offsets
		# We must align the polygon with the sprite's position and centering
		if combatant_sprite.centered:
			collision_poly.position -= texture.get_size() / 2
		
		# Add the sprite's local position so the collision follows the sprite
		collision_poly.position += combatant_sprite.position
		
		# 6. Add as child of the AREA2D
		interactable_area.add_child(collision_poly)

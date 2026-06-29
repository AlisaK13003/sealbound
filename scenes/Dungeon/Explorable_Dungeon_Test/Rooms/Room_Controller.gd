extends Node3D

class_name room

@onready var walls = $Walls
#@onready var pillars = $Pillars
@onready var lights = $SpotLight3D

@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room", "T_Chest_Room", "Quest_Room") var room_classification
@export var has_pillars: bool = false
var has_been_entered = false

var is_visible: bool = false

var room_coords: Vector2i = Vector2i(0, 0)

var room_directions

signal entered

var p_ref: explorable_dungeon

func give_player_chest_item():
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()
	
	var chance: float = rng.randf()
	var items_gotten: Array

	p_ref.current_dungeon.chest_drops.sort()
	var accumulated_chance: float = 0.0
	var drop_chances_: Array[float]
	for drop_chance in p_ref.current_dungeon.chest_drops.values():
		drop_chances_.append(drop_chance)
		
	drop_chances_.sort_custom(func(a, b): return drop_chances_[a] < drop_chances_[b])
		
	for new_chance in drop_chances_:
		if chance < new_chance + accumulated_chance:
			GlobalCombatInformation.add_item(p_ref.current_dungeon.chest_drops.find_key(new_chance))
			p_ref.player.display_obtained_items(p_ref.current_dungeon.chest_drops.find_key(new_chance))
			break
		accumulated_chance += new_chance

func _setup(p_ref_: explorable_dungeon, group_id, is_center: bool = false, quest_type: quest = null):
	self.p_ref = p_ref_
	var wall_children = $Walls.get_children()
	if room_classification == 1:
		get_node("StairDownTeleporter").go_down_floor.connect(p_ref.entered_new_floor)
	elif room_classification == 7:
		$Chest.chest_opened.connect(give_player_chest_item)	
	
	for floor_panel in $Floor.get_children():
		if p_ref.current_dungeon.type_of_dungeon == floor_panel.get_index():
			floor_panel.visible = true
		else:
			floor_panel.visible = false
		
	for child in wall_children:
		child._setup(p_ref.current_dungeon.type_of_dungeon, p_ref.player.camera_pivot.rotation_degrees.y, self.rotation_degrees.y)
	
	$SpotLight3D.light_color = Color(p_ref.current_dungeon.dungeon_light_color)
	
	if quest_type != null:
		$SpinningSprite._setup(quest_type)
		
	
	if group_id == -2:
		return
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()
	var spawn_clutter = rng.randf()
	var clutter_spawn_chance = 1
	if group_id == -1:
		clutter_spawn_chance = 0.3
	
	if spawn_clutter < clutter_spawn_chance:
		var clutter = $Clutter
		clutter.visible = true
		match group_id:
			-1:
				var non_templated_clutter = clutter.get_child(p_ref.current_dungeon.type_of_dungeon)
				non_templated_clutter.visible = true
				non_templated_clutter.get_child(1).visible = true
				var children = non_templated_clutter.get_child(1).get_children()
				if children.is_empty():
					return
					
				for child in children:
					child.visible = false
					
				var picked_child = non_templated_clutter.get_child(1).get_children().pick_random()
				picked_child.visible = true
				var template_clutter = clutter.find_children("*", "CollisionShape3D", true, false)
				if not template_clutter.is_empty():
					for child in template_clutter:
						child.set_deferred("disabled", true)
				picked_child.set_deferred("disabled", false)
			1:
				pass
			2:
				pass
			3:
				if room_classification == 5 and is_center:
					var template_clutter = clutter.get_child(p_ref.current_dungeon.type_of_dungeon)
					template_clutter.visible = true
					template_clutter.get_child(0).visible = true
					template_clutter.get_child(0).get_children().pick_random().visible = true
					
				elif room_classification == 3:
					var template_clutter = clutter.get_child(p_ref.current_dungeon.type_of_dungeon)
					template_clutter.visible = true
					template_clutter.get_child(0).visible = true
					template_clutter.get_child(0).get_children().pick_random().visible = true
					
					var non_template_clutter = clutter.get_child(p_ref.current_dungeon.type_of_dungeon).get_child(1).find_children("*", "CollisionShape3D", true, false)
					if not non_template_clutter.is_empty():
						non_template_clutter[0].set_deferred("disabled", true)
			4:
				pass
			5:
				pass

	
	#if has_pillars:
	#	for pillar in $Pillars.get_children():
	#		if pillar.get_index() == p_ref.current_dungeon.type_of_dungeon - 1:
	#			pillar.visible = true
	#		else:
	#			pillar.visible = false
	#else:
	#	$Pillars.visible = false

func return_desired_camera_angle():
	var directions_array = []
	if typeof(room_directions) == TYPE_ARRAY:
		directions_array = room_directions
	elif typeof(room_directions) in [TYPE_INT, TYPE_FLOAT]:
		directions_array = [int(room_directions)]

	var opposite_vectors = {
		0: Vector2(0, -1), 
		1: Vector2(0, 1), 
		2: Vector2(-1, 0), 
		3: Vector2(1, 0)   
	}

	if room_classification in [0, 1, 2, 7]:
		if directions_array.size() > 0:
			var dir = directions_array[0]
			if dir in opposite_vectors:
				return int(round(rad_to_deg(opposite_vectors[dir].angle())))
		return 0

	elif room_classification == 3:
		if directions_array.size() >= 2:
			var vec_sum = Vector2.ZERO
			for d in directions_array:
				if d in opposite_vectors:
					vec_sum += opposite_vectors[d]
			if vec_sum != Vector2.ZERO:
				return int(round(rad_to_deg(vec_sum.angle())))
		return 45

	elif room_classification == 4:
		var missing_dir = -1
		for d in [0, 1, 2, 3]:
			if d not in directions_array:
				missing_dir = d
				break
				
		if missing_dir != -1:
			var wall_facing_angles = {
				0: 90,  
				1: -90, 
				2: 0,   
				3: 180   
			}
			return wall_facing_angles[missing_dir]
		return 45

	elif room_classification == 5:
		return 45

	elif room_classification == 6:
		if 0 in directions_array or 1 in directions_array:
			return 0
		else:
			return 90

	else:
		return 180

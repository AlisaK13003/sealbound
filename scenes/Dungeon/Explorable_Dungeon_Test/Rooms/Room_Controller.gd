extends Node3D

class_name room

@onready var walls = $Walls
#@onready var pillars = $Pillars
@onready var lights = $SpotLight3D

@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room", "T_Chest_Room", "Quest_Room", "Special_Room", "No_Connections") var room_classification
@export var has_pillars: bool = false
var has_been_entered = false

var is_visible: bool = false

var room_coords: Vector2i = Vector2i(0, 0)

var room_directions

var is_locked: bool = false
var has_key: bool = false

signal entered

var p_ref: explorable_dungeon

func give_player_chest_item():
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()
	
	var chance: float = rng.randf()
	var selected_drop_items: Array = []
	var accumulated_chance: float = 0.0

	for drop_items in p_ref.current_dungeon.chest_drops.keys():
		var drop_chance: float = float(p_ref.current_dungeon.chest_drops[drop_items])
		if chance < accumulated_chance + drop_chance:
			selected_drop_items = drop_items
			break
		accumulated_chance += drop_chance

	if selected_drop_items.is_empty() and not p_ref.current_dungeon.chest_drops.is_empty():
		selected_drop_items = p_ref.current_dungeon.chest_drops.keys().back()

	var selected_item_paths: Array[String] = []
	var selected_equipment_entries: Array[Dictionary] = []
	collect_drop_rewards(selected_drop_items, selected_item_paths, selected_equipment_entries)
	if selected_item_paths.is_empty() and selected_equipment_entries.is_empty():
		return

	if not selected_item_paths.is_empty():
		GlobalCombatInformation.add_item(selected_item_paths)
	for equipment_entry in selected_equipment_entries:
		GlobalCombatInformation.add_equipment_to_list(str(equipment_entry["path"]), bool(equipment_entry["is_weapon"]))
	p_ref.player.display_obtained_items(selected_drop_items)

func collect_drop_rewards(drop_items: Array, item_paths: Array[String], equipment_entries: Array[Dictionary]) -> void:
	for item in drop_items:
		if item == null:
			continue
		var loaded_item: Resource = resolve_drop_resource(item)
		if loaded_item == null:
			continue
		var item_path := resolve_drop_path(item, loaded_item)
		if item_path.is_empty():
			continue
		if loaded_item is Items:
			item_paths.append(item_path)
		elif loaded_item is weapon:
			equipment_entries.append({
				"path": item_path,
				"is_weapon": true
			})
		elif loaded_item is equipment:
			equipment_entries.append({
				"path": item_path,
				"is_weapon": false
			})

func resolve_drop_resource(item) -> Resource:
	if item is Resource:
		return item
	if item is String:
		var item_path := str(item)
		if not item_path.is_empty():
			return load(item_path)
	return null

func resolve_drop_path(item, loaded_item: Resource) -> String:
	if item is String:
		return str(item)
	if loaded_item.has_method("get_path_custom"):
		return str(loaded_item.get_path_custom())
	return loaded_item.resource_path

func set_key_spawn(boss_key: bool = false):
	$SpinningSprite._setup(null, true, boss_key)
	has_key = true

func lock_room(boss_room):
	$Room_Lock.visible = true
	is_locked = true
	$Room_Lock._setup(boss_room)
	for clutter_child in $Room_Lock.find_children("*", "CollisionShape3D", true, false):
		clutter_child.set_deferred("disabled", false)

func initiate_boss_fight(body):
	if body.is_in_group("3D_Player"):
		p_ref.movement_locked = true
		p_ref.battle_initiated(p_ref.current_dungeon.boss_encounter.encounterable_enemy, 0, true)

func _setup(p_ref_: explorable_dungeon, group_id, is_center: bool = false, spawn_boss_sprite: bool = false, is_locked_ = false, quest_type: quest = null):
	self.p_ref = p_ref_
	var wall_children = $Walls.get_children()
	if room_classification == 1:
		get_node("StairDownTeleporter").go_down_floor.connect(p_ref.request_stair_transition)
	elif room_classification == 7:
		$Chest.chest_opened.connect(give_player_chest_item)	
	elif room_classification == 8:
		if quest_type != null:
			$SpinningSprite._setup(quest_type)
			var clutter = get_node_or_null("Clutter")
			if clutter != null: clutter.queue_free()
		else:
			$SpinningSprite.queue_free()
	elif room_classification == 9:
		$SpinningSprite._setup()
	
	if spawn_boss_sprite:
		var boss_sprite_node = $Boss_Sprite/AnimatedSprite3D
		$Boss_Sprite.visible = true
		boss_sprite_node.sprite_frames = p_ref.current_dungeon.boss_encounter.encounterable_enemy.sprite_frames
		boss_sprite_node.play("Idle")
		boss_sprite_node.visible = true
		$Boss_Sprite/Area3D.connect("body_entered", initiate_boss_fight)

	
	for floor_panel in $Floor.get_children():
		if p_ref.current_dungeon.type_of_dungeon == floor_panel.get_index():
			floor_panel.visible = true
		else:
			floor_panel.visible = false
			floor_panel.queue_free()
		
	for child in wall_children:
		child._setup(p_ref.current_dungeon.type_of_dungeon, p_ref.player.camera_pivot.rotation_degrees.y, self.rotation_degrees.y)
	
	$SpotLight3D.light_color = Color(p_ref.current_dungeon.dungeon_light_color)
	
	if group_id == -2:
		return
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()
	var spawn_clutter = rng.randf()
	var clutter_spawn_chance = 1
	if group_id == -1:
		clutter_spawn_chance = 0.3
	
	var clutter = get_node_or_null("Clutter")
	if clutter != null:
		for clutter_child in clutter.find_children("*", "CollisionShape3D", true, false):
			clutter_child.set_deferred("disabled", true)
		if spawn_clutter < clutter_spawn_chance:
			
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

				4:
					pass
				5:
					pass
		else:
			clutter.queue_free()
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

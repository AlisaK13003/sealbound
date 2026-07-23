extends Node

class_name state_manager

var hearthwynn_hub_scene: String = "res://scenes/main/hearthwynn.res"
var cliff_side_scene: String = "res://scenes/main/Cliff Siude.tscn"
var spooky_forest_scene: String = "res://scenes/main/Forest.tscn"
var building_insides_scene: String = "res://scenes/main/new_building_insides.res"
var player_scene: String = "res://scenes/main/player.tscn"

var hearthwynn_instance
var cliff_side_instance
var spooky_forest_instance
var building_insides_instance
var player_instance

var active_scene

var currently_transitioning: bool = false

@export var building_insides_player_speed: float = 250.0
@export var hearthwynn_player_speed: float = 250.0
@export var cliff_side_player_speed: float = 325.0
@export var forest_player_speed: float = 325.0


func _setup(transition = true):
	currently_transitioning = transition
	Fade.fade_out(0.0)
	var hearthwynn = load(hearthwynn_hub_scene)
	var cliff_side = load(cliff_side_scene)
	var spooky_forest = load(spooky_forest_scene)
	var building_insides = load(building_insides_scene)
	var player_node = load(player_scene)
	
	hearthwynn_instance = hearthwynn.instantiate()
	cliff_side_instance = cliff_side.instantiate()
	spooky_forest_instance = spooky_forest.instantiate()
	building_insides_instance = building_insides.instantiate()
	player_instance = player_node.instantiate()
	
func wipe_for_dungeon():
	hearthwynn_instance.queue_free()
	cliff_side_instance.queue_free()
	spooky_forest_instance.queue_free()
	building_insides_instance.queue_free()
	player_instance.queue_free()
	
func swap_scene(scene_to_remove = null):
	_perform_swap_scene.call_deferred(scene_to_remove)

func _perform_swap_scene(scene_to_remove = null):
	currently_transitioning = true
	Global.time_paused = true
	var scene_to_swap_to: Node = null
	
	if scene_to_remove != null:
		active_scene = scene_to_remove
		
	if active_scene == null:
		active_scene = get_tree().current_scene
		
	if active_scene != null and active_scene.get_parent() != null:
		active_scene.get_parent().remove_child(active_scene)
		
	match Global.current_region:
		"Buildings_Insides":
			scene_to_swap_to = building_insides_instance
		"Village":
			scene_to_swap_to = hearthwynn_instance
		"Cliff Side":
			scene_to_swap_to = cliff_side_instance
		"Forest":
			scene_to_swap_to = spooky_forest_instance
		_:
			scene_to_swap_to = hearthwynn_instance 
	
	if scene_to_swap_to.get_parent() != get_tree().root:
		if scene_to_swap_to.get_parent() != null:
			scene_to_swap_to.get_parent().remove_child(scene_to_swap_to)
		get_tree().root.add_child(scene_to_swap_to)
	
	get_tree().current_scene = scene_to_swap_to

	if player_instance.get_parent() != scene_to_swap_to:
		if player_instance.get_parent() != null:
			player_instance.get_parent().remove_child(player_instance)
		scene_to_swap_to.add_child(player_instance)
		
	player_instance.move_speed = get_player_speed_for_region(Global.current_region)
	player_instance.scale = Vector2(1.0, 1.0)
		
	scene_to_swap_to.swap_to_me()

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print(scene_to_swap_to.scene_file_path)
	
	active_scene = scene_to_swap_to
	Global.current_loading_zone = "" 
	currently_transitioning = false
	Global.time_paused = false

func get_player_speed_for_region(region: String) -> float:
	match region:
		"Buildings_Insides":
			return building_insides_player_speed
		"Village":
			return hearthwynn_player_speed
		"Cliff Side":
			return cliff_side_player_speed
		"Forest":
			return forest_player_speed
	return hearthwynn_player_speed

extends Node

class_name state_manager

var hearthwynn_hub_scene: String = "res://scenes/main/Hearthwynn.tscn"
var cliff_side_scene: String = "res://scenes/main/Cliff Siude.tscn"
var spooky_forest_scene: String = "res://scenes/main/Forest.tscn"
var building_insides_scene: String = "res://scenes/main/Building Insides.tscn"

var hearthwynn_instance
var cliff_side_instance
var spooky_forest_instance
var building_insides_instance

var active_scene

var currently_transitioning: bool = false

func _ready():
	currently_transitioning = true
	Fade.fade_out(0.0)
	var hearthwynn = load(hearthwynn_hub_scene)
	var cliff_side = load(cliff_side_scene)
	var spooky_forest = load(spooky_forest_scene)
	var building_insides = load(building_insides_scene)
	
	hearthwynn_instance = hearthwynn.instantiate()
	cliff_side_instance = cliff_side.instantiate()
	spooky_forest_instance = spooky_forest.instantiate()
	building_insides_instance = building_insides.instantiate()

func _setup(transition = true):
	currently_transitioning = transition
	Fade.fade_out(0.0)
	var hearthwynn = load(hearthwynn_hub_scene)
	var cliff_side = load(cliff_side_scene)
	var spooky_forest = load(spooky_forest_scene)
	var building_insides = load(building_insides_scene)
	
	hearthwynn_instance = hearthwynn.instantiate()
	cliff_side_instance = cliff_side.instantiate()
	spooky_forest_instance = spooky_forest.instantiate()
	building_insides_instance = building_insides.instantiate()
	
func swap_scene(scene_to_remove = null):
	_perform_swap_scene.call_deferred(scene_to_remove)

func _perform_swap_scene(scene_to_remove = null):
	currently_transitioning = true
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
	
	get_tree().root.add_child(scene_to_swap_to)
	
	scene_to_swap_to.swap_to_me()
	
	get_tree().current_scene = scene_to_swap_to
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	active_scene = scene_to_swap_to
	Global.current_loading_zone = "" 
	currently_transitioning = false
	

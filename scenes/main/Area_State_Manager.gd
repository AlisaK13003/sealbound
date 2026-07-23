extends Node

class_name state_manager

var hearthwynn_hub_scene: String = "res://scenes/main/hearthwynn.res"
var cliff_side_scene: String = "res://scenes/main/Cliff Siude.tscn"
var spooky_forest_scene: String = "res://scenes/main/Forest.tscn"
var building_insides_scene: String = "res://scenes/main/new_building_insides.res"
var player_scene: String = "res://scenes/main/player.tscn"
const ENVIRONMENT_HANDLER_SCRIPT: Script = preload("res://assets/Resources/Interactables/Teleports/EnvironmentHandler.gd")
const BUILDING_BGM_PATH: String = "res://assets/Audio/BGM/Week 17 - Alley Cat DUMPSTER DIVIN.ogg"
const BUILDING_INSIDE_LOADING_ZONE_CONFIG := {
	"Apothecary": {
		"current_region": "Buildings_Insides",
		"current_spot": "Apothecary",
		"target_region": "Forest",
		"target_spot": "Apothecary",
	},
	"Infirmary": {
		"current_region": "Buildings_Insides",
		"current_spot": "Infirmary",
		"target_region": "Village",
		"target_spot": "Infirmary",
	},
	"Library": {
		"current_region": "Buildings_Insides",
		"current_spot": "Library",
		"target_region": "Village",
		"target_spot": "Library",
	},
	"Tavern": {
		"current_region": "Buildings_Insides",
		"current_spot": "Tavern",
		"target_region": "Village",
		"target_spot": "Tavern",
	},
	"Bedroom": {
		"current_region": "Buildings_Insides",
		"current_spot": "Bedroom",
		"target_region": "Buildings_Insides",
		"target_spot": "Bedroom_Exit",
	},
	"Bedroom_Exit": {
		"current_region": "Buildings_Insides",
		"current_spot": "Bedroom_Exit",
		"target_region": "Buildings_Insides",
		"target_spot": "Bedroom",
	},
	"Bedspawn": {
		"current_region": "Buildings_Insides",
		"current_spot": "Bedspawn",
		"target_region": "Buildings_Insides",
		"target_spot": "Bedroom",
	},
	"House_1": {
		"current_region": "Buildings_Insides",
		"current_spot": "House_1",
		"target_region": "Village",
		"target_spot": "House_1",
	},
	"House_2": {
		"current_region": "Buildings_Insides",
		"current_spot": "House_2",
		"target_region": "Village",
		"target_spot": "House_2",
	},
	"House_3": {
		"current_region": "Buildings_Insides",
		"current_spot": "House_3",
		"target_region": "Village",
		"target_spot": "House_3",
	},
	"Blacksmith": {
		"current_region": "Buildings_Insides",
		"current_spot": "Blacksmith",
		"target_region": "Village",
		"target_spot": "Blacksmith2",
	},
	"Blacksmith2": {
		"current_region": "Buildings_Insides",
		"current_spot": "Blacksmith2",
		"target_region": "Village",
		"target_spot": "Blacksmith2",
	},
}

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
	ensure_environment_handler(building_insides_instance, true)
	configure_building_inside_loading_zones(building_insides_instance)
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
		
	if not scene_to_swap_to.has_method("swap_to_me"):
		ensure_environment_handler(scene_to_swap_to, Global.current_region == "Buildings_Insides")
	if scene_to_swap_to.has_method("swap_to_me"):
		scene_to_swap_to.swap_to_me()
	else:
		push_error("AreaStateManager: Scene '%s' does not have swap_to_me()." % scene_to_swap_to.scene_file_path)

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

func ensure_environment_handler(scene_root: Node, is_building_insides: bool = false) -> void:
	if scene_root == null or scene_root.has_method("swap_to_me"):
		return
	scene_root.set_script(ENVIRONMENT_HANDLER_SCRIPT)
	if is_building_insides:
		scene_root.set("is_building_insides", true)
		scene_root.set("bgm", load(BUILDING_BGM_PATH))

func configure_building_inside_loading_zones(scene_root: Node) -> void:
	if scene_root == null:
		return

	for room_name in BUILDING_INSIDE_LOADING_ZONE_CONFIG.keys():
		var loading_zone := scene_root.get_node_or_null("%s/LoadingZone" % room_name)
		if loading_zone == null:
			push_warning("AreaStateManager: Missing loading zone for building room '%s'." % room_name)
			continue

		var config: Dictionary = BUILDING_INSIDE_LOADING_ZONE_CONFIG[room_name]
		loading_zone.set("Current Location/Region", config["current_region"])
		loading_zone.set("Current Location/Spot", config["current_spot"])
		loading_zone.set("Destination Location/Region", config["target_region"])
		loading_zone.set("Destination Location/Spot", config["target_spot"])

extends Control

@export var dungeon_scenes: Array[String]
var current_selected_dungeon: int = 0

@onready var dungeon_select_buttons = $CanvasLayer/HBoxContainer
@onready var container_thing = $CanvasLayer/Control

@onready var hidden_load = $CanvasLayer/ColorRect

@onready var background = $TextureRect

@onready var return_to_hearthwynn = $CanvasLayer/HBoxContainer2/GenericButton2
@onready var travel_to_dungeon = $CanvasLayer/HBoxContainer2/GenericButton

func _ready():
	hidden_load.visible = false
	
	return_to_hearthwynn.activated.connect(travel.bind(false))
	travel_to_dungeon.activated.connect(travel.bind(true))
	
	for child in dungeon_select_buttons.get_children():
		child.pressed.connect(change_selected_dungeon.bind(child.get_index()))
		
	for dungeon in GlobalCombatInformation.dungeon_types:
		container_thing.get_child(GlobalCombatInformation.dungeon_types.find(dungeon))._setup(dungeon)
		dungeon_select_buttons.get_child(GlobalCombatInformation.dungeon_types.find(dungeon)).update_name(dungeon.dungeon_name)
		
	for button in dungeon_select_buttons.get_children():
		if button.button_name_text.text == "Soon":
			button.visible = false
		
	for child in container_thing.get_children():
		if child.get_index() == 0:
			child.visible = true
		else:
			child.visible = false
	await Fade.fade_out(0.5)

var in_cycle = false
func _physics_process(delta):
	if not in_cycle:
		in_cycle = true
		background.rotation_degrees = -360
		var tween = create_tween()
		tween.tween_property(background, "rotation", 360, 360)
		await tween.finished
		in_cycle = false

func change_selected_dungeon(dungeon_select):
	hide_all_info()
	current_selected_dungeon = dungeon_select
	container_thing.get_child(dungeon_select).visible = true

func hide_all_info():
	for child in container_thing.get_children():
		child.visible = false

func travel(set_off_for_dungeon):
	if set_off_for_dungeon:
		await Fade.fade_in(1)
		await GlobalCombatInformation.load_items()
		GlobalCombatInformation.transition_to_dungeon(current_selected_dungeon)
	else:
		await Fade.fade_in(1)
		Fade.change_scene("res://scenes/main/Hearthwynn.tscn")

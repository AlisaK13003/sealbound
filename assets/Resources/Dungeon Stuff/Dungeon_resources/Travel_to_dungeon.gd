extends Control

@export var dungeon_scenes: Array[String]
var current_selected_dungeon: int = 0

@onready var container_thing = $CanvasLayer/Control

@onready var hidden_load = $CanvasLayer/ColorRect

@onready var background = $TextureRect

@onready var return_to_hearthwynn = $CanvasLayer/HBoxContainer2/GenericButton2
@onready var travel_to_dungeon = $CanvasLayer/HBoxContainer2/GenericButton

@onready var menu_tabs = $MenuTabs

@export var menu_tab_icons: Array[Texture2D]

func _ready():
	hidden_load.visible = false
	
	return_to_hearthwynn.activated.connect(travel.bind(false))
	travel_to_dungeon.activated.connect(travel.bind(true))
		
	for dungeon in GlobalCombatInformation.dungeon_types:
		container_thing.get_child(GlobalCombatInformation.dungeon_types.find(dungeon))._setup(dungeon)

	menu_tabs._setup(["hi", "HI"], "res://assets/Resources/Dungeon Stuff/Select_screen_dungeon_tab.tscn", menu_tab_icons)

	menu_tabs.selection_changed.connect(_tab_changed)

	apply_demo_dungeon_locks()
	show_selected_dungeon()
	await Fade.fade_out(0.5)

func _tab_changed(which_tab):
	for child in container_thing.get_children():
		if child.get_index() == which_tab:
			child.visible = true
		else:
			child.visible = false

var in_cycle = false
func _physics_process(_delta):
	if not in_cycle:
		in_cycle = true
		background.rotation_degrees = -360
		var tween = create_tween()
		tween.tween_property(background, "rotation", 360, 360)
		await tween.finished
		in_cycle = false

func apply_demo_dungeon_locks() -> void:
	var found_unlocked_dungeon := false

	for child in container_thing.get_children():
		child.visible = false

	for button in menu_tabs.get_children():
		var dungeon_index: int = button.get_index()
		var has_dungeon: bool = dungeon_index < GlobalCombatInformation.dungeon_types.size()
		var is_unlocked: bool = has_dungeon and Global.is_demo_dungeon_unlocked(dungeon_index)
		button.visible = is_unlocked
		if is_unlocked and not found_unlocked_dungeon:
			current_selected_dungeon = dungeon_index
			found_unlocked_dungeon = true

	if not found_unlocked_dungeon:
		current_selected_dungeon = -1

func show_selected_dungeon() -> void:
	hide_all_info()
	if current_selected_dungeon >= 0 and current_selected_dungeon < container_thing.get_child_count():
		container_thing.get_child(current_selected_dungeon).visible = true

func is_dungeon_unlocked(dungeon_select: int) -> bool:
	return dungeon_select >= 0 and dungeon_select < GlobalCombatInformation.dungeon_types.size() and Global.is_demo_dungeon_unlocked(dungeon_select)

func show_dungeon_locked_message(dungeon_select: int) -> void:
	if not Global.has_story_flag(Global.STORY_FLAG_LYRA_AXE_QUEST_STARTED):
		Global.show_mc_thought(Global.LYRA_FIRST_OBJECTIVE_TEXT)
	elif dungeon_select == Global.DUNGEON_INDEX_CAVE:
		Global.show_mc_thought("I do not have a reason to go there yet.")
	else:
		Global.show_mc_thought("I cannot go there yet.")

func change_selected_dungeon(dungeon_select):
	if not is_dungeon_unlocked(dungeon_select):
		show_dungeon_locked_message(dungeon_select)
		return
	hide_all_info()
	current_selected_dungeon = dungeon_select
	container_thing.get_child(dungeon_select).visible = true

func hide_all_info():
	for child in container_thing.get_children():
		child.visible = false

func travel(set_off_for_dungeon):
	if set_off_for_dungeon:
		if not is_dungeon_unlocked(current_selected_dungeon):
			show_dungeon_locked_message(current_selected_dungeon)
			return
		await Fade.fade_in(1)
		await GlobalCombatInformation.load_items()
		GlobalCombatInformation.transition_to_dungeon(menu_tabs.current_selection)
	else:
		await Fade.fade_in(1)
		Global.current_region = "Village"
		Global.current_location = "Village"
		Global.current_loading_zone = "Spooky Forest"
		GlobalCombatInformation.in_dungeon = false
		AreaStateManager._setup(false)
		AreaStateManager.swap_scene(self)

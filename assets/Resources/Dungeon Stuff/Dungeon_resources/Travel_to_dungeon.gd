extends Control

@export var dungeon_scenes: Array[String]
var current_selected_dungeon: int = 0

@onready var container_thing = $CanvasLayer/Control

@onready var hidden_load = $CanvasLayer/ColorRect

@onready var background = $TextureRect

@onready var return_to_hearthwynn = $CanvasLayer/HBoxContainer2/GenericButton2
@onready var travel_to_dungeon = $CanvasLayer/HBoxContainer2/GenericButton

@onready var menu_tabs = $VBoxContainer/MenuTabs

#@export var menu_tab_icons: Array[Texture2D]

var dungeon_overview_path = "res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Overview.tscn"
const LYRA_AXE_QUEST_PATH: String = "res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"

var which_dungeon
var dungeon_entries
func _ready():
	hidden_load.visible = false
	
	return_to_hearthwynn.activated.connect(travel.bind(false))
	travel_to_dungeon.activated.connect(travel.bind(true))
	
	dungeon_entries = []
	
	for dungeon in range(GlobalCombatInformation.dungeon_types.size()):
		dungeon_entries.append({
			"dungeon": GlobalCombatInformation.dungeon_types[dungeon],
			"quest": null,
			"index": dungeon
		})

	for quest_ in GlobalCombatInformation.active_quests:
		if quest_.required_spawn and quest_.special_dungeon != null and GlobalCombatInformation.completed_quests.find_custom(func(finished_quests: quest): return _is_same_special_dungeon(finished_quests, quest_)) == -1:
			dungeon_entries.append({
				"dungeon": quest_.special_dungeon,
				"quest": quest_
			})
			
	for quest_ in GlobalCombatInformation.completed_quests:
		if quest_.required_spawn and quest_.special_dungeon != null and not _is_lyra_axe_quest(quest_):
			dungeon_entries.append({
				"dungeon": quest_.special_dungeon,
				"quest": quest_.duplicate()
			})
	
	dungeon_entries.sort_custom(func(a, b):
		return a.dungeon.type_of_dungeon < b.dungeon.type_of_dungeon
	)
	
	var menu_tab_icons: Array[Texture2D] = []
	var dungeon_names = []
	
	for entry in dungeon_entries:
		var dungeon = entry.dungeon
		var quest_ = entry.quest
		
		var new_dungeon_over = load(dungeon_overview_path)
		var new_dungeon_over_inst = new_dungeon_over.instantiate()
		container_thing.add_child(new_dungeon_over_inst)
		
		if quest_ == null:
			new_dungeon_over_inst._setup(dungeon)
		else:
			new_dungeon_over_inst._setup(dungeon, quest_)
			
		dungeon_names.append(dungeon.dungeon_name)
		menu_tab_icons.append(dungeon.dungeon_background)
	
	menu_tabs._setup(dungeon_names, "res://assets/Resources/Dungeon Stuff/Select_screen_dungeon_tab.tscn", menu_tab_icons)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child).get_node("Label").text = dungeon_names[child]

	menu_tabs.selection_changed.connect(_tab_changed)
	
	for tab in menu_tabs.get_children():
		if tab.visible:
			_tab_changed(tab.get_index())
			break
			
	apply_demo_dungeon_locks()
	for child in $CanvasLayer/Control.get_children():
		child.visible = false
	await Fade.fade_out(0.5)
	

func _is_same_special_dungeon(finished_quest: quest, active_quest: quest) -> bool:
	if finished_quest == null or active_quest == null:
		return false
	if finished_quest.special_dungeon == null or active_quest.special_dungeon == null:
		return false
	return finished_quest.special_dungeon.dungeon_name == active_quest.special_dungeon.dungeon_name

func _is_lyra_axe_quest(quest_: quest) -> bool:
	if quest_ == null:
		return false
	if quest_.get_path_custom() == LYRA_AXE_QUEST_PATH:
		return true
	return quest_.quest_name == "Find Lyra's Axe"


func _tab_changed(which_tab):
	current_selected_dungeon = which_tab
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

	var count = 0
	for entry: Dictionary in dungeon_entries:
		var is_unlocked: bool = false
		if entry.has("index"):
			is_unlocked = StateManager.check_completion(entry["index"], StateManager.completion_checks.DUNGEON_CHECKS)
		elif entry.has("quest") and entry["quest"] != null:
			is_unlocked = true
		menu_tabs.get_child(count).visible = is_unlocked
		if is_unlocked and not found_unlocked_dungeon:
			$CanvasLayer/Control.get_child(count).visible = true
			found_unlocked_dungeon = true
		count += 1

func is_dungeon_unlocked(dungeon_select) -> bool:
	return StateManager.check_completion(dungeon_select, StateManager.completion_checks.DUNGEON_CHECKS)

func show_dungeon_locked_message(dungeon_select: int) -> void:
	return
	if $CanvasLayer/Control.get_child(dungeon_select).stored_dungeon.quest_dungeon:
		return
	
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
		var dungeon_type_ = $CanvasLayer/Control.get_child(current_selected_dungeon).stored_dungeon
		
		if not is_dungeon_unlocked(dungeon_type_.dungeon_unlock_type) and $CanvasLayer/Control.get_child(current_selected_dungeon).stored_quest == null:
			show_dungeon_locked_message(current_selected_dungeon)
			return
		await Fade.fade_in(1)
		#await GlobalCombatInformation.load_items()
		GlobalCombatInformation.transition_to_dungeon(dungeon_type_, $CanvasLayer/Control.get_child(current_selected_dungeon).stored_quest)
	else:
		await Fade.fade_in(1)
		Global.current_region = "Village"
		Global.current_location = "Village"
		Global.current_loading_zone = "Spooky Forest"
		GlobalCombatInformation.in_dungeon = false
		AreaStateManager._setup(false)
		AreaStateManager.swap_scene(self)

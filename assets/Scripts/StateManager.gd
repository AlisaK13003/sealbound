extends Node

var dungeon_states: Dictionary[int, bool] = {}
var story_states: Dictionary[int, bool] = {}
var seal_completion_states: Dictionary[int, bool] = {}
var party_member_unlocked: Dictionary[int, bool] = {}
var tavern_quests_taken: Dictionary[int, bool] = {}
var pseduo_story_time: int = 0

const SPEAK_TO_LYRA_QUEST_PATH: String = "res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Speak To Lyra.tres"
const LYRA_AXE_QUEST_PATH: String = "res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"

var story_triggers: Dictionary = {
	"lyra_tavern_cutscene": {
		"region": "Buildings_Insides",
		"loading_zone": "Tavern",
		"required": [story_beats_lookup.TALKED_TO_SERA_IN_INFIRMARY],
		"excluded": [story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE]
	},
	"turning_in_lyra_axe_cutscene": {
		"region": "Buildings_Insides",
		"loading_zone": "Bedroom_Exit",
		"required": [story_beats_lookup.READY_TO_TURN_IN_AXE_QUEST],
		"excluded": [story_beats_lookup.TURNED_IN_LYRA_QUEST]
	},
	"quest_board_unlock_cutscene": {
		"region": "Buildings_Insides",
		"loading_zone": "Bedroom_Exit",
		"required": [story_beats_lookup.TURNED_IN_LYRA_QUEST, story_beats_lookup.SLEPT_AFTER_LYRA_QUEST],
		"excluded": [story_beats_lookup.QUEST_BOARD_UNLOCK]
	},
	"cave_dungeon_entry": {
		"required": [story_beats_lookup.CAVE_DUNGEON_UNLOCKED]
	},
	"give_ore_to_blacksmith": {
		"region": "Buildings_Insides",
		"loading_zone": "Blacksmith",
		"required": [story_beats_lookup.READY_TO_TURN_IN_BLACKSMITH_QUEST]
	},
	"think_about_forest_clearing_mc_thought": {
		"region": "Buildings_Insides",
		"loading_zone": "Bedspawn",
		"required": [story_beats_lookup.BLACKSMITH_QUEST_FINISHED],
		"day_requirement": 5
	},
	"talk_to_sera_about_clearing": {
		"region": "Buildings_Insides",
		"loading_zone": "Infirmary",
		"required": [story_beats_lookup.CUTSCENE_TELLING_YOU_GO_BACK_TO_CLEARING]
	},
	"first_seal_dungeon_cutscene": {
		"region": "Buildings_Insides",
		"loading_zone": "Bedspawn",
		"required": [story_beats_lookup.FIRST_SEAL_DUNGEON_BEATEN]
	}
}

func clear():
	dungeon_states.clear()
	story_states.clear()
	seal_completion_states.clear()
	party_member_unlocked.clear()
	pseduo_story_time = 0

func should_trigger(trigger_id: String) -> bool:
	if not story_triggers.has(trigger_id):
		return false
		
	var config: Dictionary = story_triggers[trigger_id]
	return evaluate_conditions(config.get("required", []), config.get("excluded", []), config.get("region", ""), config.get("loading_zone", ""), config.get("day_requirement", 0))

var state_mapping: Dictionary[String, int] = {
	"sera_sent_to_lyra": story_beats_lookup.TALKED_TO_SERA_IN_INFIRMARY,
	"opening_cutscene_seen": story_beats_lookup.SEEN_OPENING_CUTSCENE
}

enum completion_checks {
	DUNGEON_CHECKS = 0,
	STORY_CHECKS = 1,
	SEAL_CHECKS = 2,
	PARTY_MEMBER_CHECKS = 3,
}

enum dungeon_state_lookup {
	CREEPY_DUNGEON_UNLOCKED = 0,
	FOREST_DUNGEON_UNLOCKED = 1,
	SEAL_DUNGEON_UNLOCKED = 2,
}

enum story_beats_lookup {
	TALKED_TO_SERA_IN_INFIRMARY = 0,
	ACCEPTED_QUEST_FOR_LYRA_AXE = 1,
	TURNED_IN_LYRA_QUEST = 2,
	QUEST_BOARD_UNLOCK = 3,
	STARTER_FOREST_DUNGEON_UNLOCKED = 4,
	BLACKSMITH_QUEST_UNLOCKED = 5,
	CUTSCENE_TELLING_YOU_GO_BACK_TO_CLEARING = 6,
	FIRST_SEAL_CUTSCENE_WATCHED = 7,
	SERA_SENT_TO_LYRA = 8,            
	CAVE_DUNGEON_UNLOCKED = 9,        
	SEEN_OPENING_CUTSCENE = 10,
	READY_TO_TURN_IN_AXE_QUEST = 11,
	BLACKSMITH_QUEST_FINISHED = 12,
	TALKED_TO_SERA_ABOUT_CLEAR = 13,
	READY_TO_TURN_IN_BLACKSMITH_QUEST = 14,
	FIRST_SEAL_DUNGEON_BEATEN = 15,
	SLEPT_AFTER_LYRA_QUEST = 16
}

enum seal_dungeon_completion {
	FOREST_SEAL_RESTORED = 0,
}

enum party_member_unlock_lookup {
	SERA_UNLOCKED = 0,
	LYRA_UNLOCKED = 1,
	ROWAN_UNLOCKED = 2,
	KAELA_UNLOCKED = 3,
	CASSIAN_UNLOCKED = 4,
	ORION_UNLOCKED = 5,
	FMC_UNLOCKED = 6,
	MMC_UNLOCKED = 7
}

enum tavern_quest_lookup {
	KILL_EYEBALLS,
	KILL_SLIMES, 
	KILL_WOLVES, 
	KILL_RED_SLIMES,
	KILL_BLUE_SLIMES,
	RETRIEVE_ORES,
	KILL_MORE_SLIMES,
}

func export_to_json() -> Dictionary:
	return {
		"dungeon_states": dungeon_states,
		"story_states": story_states,
		"seal_completion_states": seal_completion_states,
		"party_member_unlocked": party_member_unlocked,
		"tavern_quests": tavern_quests_taken,
		"story_time": str(pseduo_story_time)
	}

func load_story_states(states: Dictionary) -> void:
	dungeon_states = _convert_keys_to_int(states.get("dungeon_states", {}))
	story_states = _convert_keys_to_int(states.get("story_states", {}))
	seal_completion_states = _convert_keys_to_int(states.get("seal_completion_states", {}))
	party_member_unlocked = _convert_keys_to_int(states.get("party_member_unlocked", {}))
	tavern_quests_taken = _convert_keys_to_int(states.get("tavern_quests", {}))
	pseduo_story_time = int(states.get("story_time", 0))

func _convert_keys_to_int(raw_dict: Dictionary) -> Dictionary[int, bool]:
	var typed_dict: Dictionary[int, bool] = {}
	for key in raw_dict:
		typed_dict[int(key)] = bool(raw_dict[key])
	return typed_dict

func get_beat_enum_from_string(key_str: String) -> int:
	for key in story_beats_lookup.values():
		if key == state_mapping[key_str]:
			return key
	return -1

func check_completion(story_check: int, type_of_check: int) -> bool:
	match type_of_check:
		completion_checks.DUNGEON_CHECKS:
			return search_dict(dungeon_states, story_check)
		completion_checks.STORY_CHECKS:
			return search_dict(story_states, story_check)
		completion_checks.SEAL_CHECKS:
			return search_dict(seal_completion_states, story_check)
		completion_checks.PARTY_MEMBER_CHECKS:
			return search_dict(party_member_unlocked, story_check)
	return false

func search_dict(dictionary: Dictionary[int, bool], story_check: int) -> bool:
	return dictionary.get(story_check, false)

func set_party_member_unlock(key: int, value: bool = true):
	party_member_unlocked[key] = value
	if value:
		GlobalCombatInformation.update_available_party_members.emit()

func set_dungeon_unlock(key: int, value: bool = true):
	dungeon_states[key] = value

signal state_set
func set_story_state(key: int, value: bool = true) -> void:
	story_states[key] = value
	state_set.emit()

func has_story_state(key: int) -> bool:
	return story_states.get(key, false)

func set_seal_state(key: int, value: bool = true):
	seal_completion_states[key] = value
	state_set.emit()

func check_seal_state(key: int) -> bool:
	return seal_completion_states.get(key, false)

func set_quest_take(key: int, value: bool = true):
	tavern_quests_taken[key] = value

func has_quest_been_take(key: int) -> bool:
	return tavern_quests_taken.get(key, false)

func start_story_beat(beat: int) -> void:
	set_story_state(beat, true)
	print("[Story] Beat reached: ", beat)

var currently_available_quests = []
signal new_state
func add_quests_to_board():
	currently_available_quests.clear()
	var quests_to_add = []
	if check_completion(story_beats_lookup.QUEST_BOARD_UNLOCK, completion_checks.STORY_CHECKS) and not has_quest_been_take(tavern_quest_lookup.RETRIEVE_ORES):
		quests_to_add.append(add_quest("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve_Ores.tres"))
	if check_completion(story_beats_lookup.STARTER_FOREST_DUNGEON_UNLOCKED, completion_checks.STORY_CHECKS) and not has_quest_been_take(tavern_quest_lookup.KILL_SLIMES):
		quests_to_add.append(add_quest("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Gather Slime.tres"))
	if check_completion(story_beats_lookup.BLACKSMITH_QUEST_FINISHED, completion_checks.STORY_CHECKS) and not has_quest_been_take(tavern_quest_lookup.KILL_EYEBALLS):
		quests_to_add.append(add_quest("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	if check_completion(story_beats_lookup.BLACKSMITH_QUEST_FINISHED, completion_checks.STORY_CHECKS) and not has_quest_been_take(tavern_quest_lookup.KILL_MORE_SLIMES):
		quests_to_add.append(add_quest("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_More_Slimes.tres"))

	for quest_: quest in quests_to_add:
		var index = currently_available_quests.find_custom(func(available_quests: quest): return quest_.quest_name == available_quests.quest_name)
		if index == -1:
			currently_available_quests.append(quest_.duplicate())

func add_quest(quest_path):
	var mew_item = load(quest_path)
	var temp_copy = mew_item.duplicate()
	
	temp_copy.set_meta("original_path", mew_item.resource_path)
	return temp_copy

func start_speak_to_lyra_quest() -> void:
	_add_story_quest_once(SPEAK_TO_LYRA_QUEST_PATH, "Sera sent you to Lyra")

func complete_speak_to_lyra_quest() -> void:
	if _has_active_quest(SPEAK_TO_LYRA_QUEST_PATH):
		GlobalCombatInformation.complete_quest(SPEAK_TO_LYRA_QUEST_PATH)
		GlobalCombatInformation.check_quest_progress.emit()
		print("[Story] Completed speak to Lyra quest.")

func start_lyra_axe_quest() -> void:
	set_story_state(story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE)
	set_party_member_unlock(party_member_unlock_lookup.LYRA_UNLOCKED)
	GlobalCombatInformation.add_party_member_by_character_index(party_member_unlock_lookup.LYRA_UNLOCKED, true)

	for existing_quest in GlobalCombatInformation.active_quests:
		if existing_quest != null and existing_quest.resource_path == LYRA_AXE_QUEST_PATH:
			print("[Story] Lyra axe quest already active.")
			GlobalCombatInformation.check_quest_progress.emit()
			return

	var lyra_quest: quest = load(LYRA_AXE_QUEST_PATH)
	if lyra_quest == null:
		push_warning("Global: Could not load Lyra axe quest: %s" % LYRA_AXE_QUEST_PATH)
		return

	GlobalCombatInformation.add_quest(LYRA_AXE_QUEST_PATH)
	print("[Story] Started Lyra axe quest.")

func turn_in_lyra_axe_quest() -> void:
	if has_story_state(story_beats_lookup.TURNED_IN_LYRA_QUEST):
		return
	pseduo_story_time = Global.current_day
	GlobalCombatInformation.complete_quest(LYRA_AXE_QUEST_PATH)
	GlobalCombatInformation.check_quest_progress.emit()
	set_dungeon_unlock(dungeon_state_lookup.FOREST_DUNGEON_UNLOCKED, true)
	set_story_state(story_beats_lookup.TURNED_IN_LYRA_QUEST, true)
	print("[Story] Turned in Lyra axe quest.")

func mark_slept_after_lyra_quest() -> void:
	if not has_story_state(story_beats_lookup.TURNED_IN_LYRA_QUEST):
		return
	if has_story_state(story_beats_lookup.QUEST_BOARD_UNLOCK):
		return
	set_story_state(story_beats_lookup.SLEPT_AFTER_LYRA_QUEST, true)
	print("[Story] Slept after Lyra axe quest.")

func unlock_quest_board_and_demo_party() -> void:
	set_story_state(story_beats_lookup.QUEST_BOARD_UNLOCK, true)
	set_party_member_unlock(party_member_unlock_lookup.SERA_UNLOCKED)
	set_party_member_unlock(party_member_unlock_lookup.LYRA_UNLOCKED)
	GlobalCombatInformation.add_party_member_by_character_index(party_member_unlock_lookup.SERA_UNLOCKED, true)
	GlobalCombatInformation.add_party_member_by_character_index(party_member_unlock_lookup.LYRA_UNLOCKED, true)
	add_quests_to_board()
	new_state.emit()
	print("[Story] Quest board unlocked. Sera and Lyra can join dungeons.")

func _add_story_quest_once(quest_path: String, log_label: String) -> void:
	if _has_active_quest(quest_path) or _has_completed_quest(quest_path):
		GlobalCombatInformation.check_quest_progress.emit()
		return

	var story_quest: quest = load(quest_path)
	if story_quest == null:
		push_warning("Global: Could not load story quest: %s" % quest_path)
		return

	GlobalCombatInformation.add_quest(quest_path)
	print("[Story] Started quest: ", log_label)

func _has_active_quest(quest_path: String) -> bool:
	return _has_quest_in_list(GlobalCombatInformation.active_quests, quest_path)

func _has_completed_quest(quest_path: String) -> bool:
	return _has_quest_in_list(GlobalCombatInformation.completed_quests, quest_path)

func _has_quest_in_list(quests_to_search: Array, quest_path: String) -> bool:
	var source_quest: quest = load(quest_path)
	var quest_name := source_quest.quest_name if source_quest != null else ""
	for existing_quest in quests_to_search:
		if existing_quest == null:
			continue
		if existing_quest.get_path_custom() == quest_path:
			return true
		if not quest_name.is_empty() and existing_quest.quest_name == quest_name:
			return true
	return false


func evaluate_conditions(required_beats: Array = [], excluded_beats: Array = [], target_region: String = "", target_loading_zone: String = "", day_requirement: int = false) -> bool:
	if not target_region.is_empty() and Global.current_region != target_region:
		return false
		
	if not target_loading_zone.is_empty() and Global.current_loading_zone != target_loading_zone:
		return false
		
	for beat in required_beats:
		if not has_story_state(beat):
			return false
			
	for beat in excluded_beats:
		if has_story_state(beat):
			return false
	
	if pseduo_story_time + day_requirement > Global.current_day:
		return false
	
	return true

func should_start_lyra_tavern_cutscene(loading_zone_name: String) -> bool:
	return (
		Global.current_region == "Buildings_Insides" 
		and loading_zone_name == "Tavern" 
		and has_story_state(story_beats_lookup.TALKED_TO_SERA_IN_INFIRMARY) 
		and not has_story_state(story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE)
	)

func debug_unlock_cave_dungeon() -> void:
	set_story_state(story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE)
	set_story_state(story_beats_lookup.CAVE_DUNGEON_UNLOCKED)
	print("[Debug] Cave dungeon unlocked for testing.")

	var current_scene = get_tree().current_scene
	if current_scene != null:
		if current_scene.has_method("apply_demo_dungeon_locks"):
			current_scene.apply_demo_dungeon_locks()
		if current_scene.has_method("show_selected_dungeon"):
			current_scene.show_selected_dungeon()

func debug_skip_to_lyra_axe_sleep_setup() -> void:
	Global.set_calendar_time(0, 0, 22, 0)
	set_story_state(story_beats_lookup.SEEN_OPENING_CUTSCENE)
	set_story_state(story_beats_lookup.TALKED_TO_SERA_IN_INFIRMARY)
	set_story_state(story_beats_lookup.SERA_SENT_TO_LYRA)
	set_story_state(story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE)
	set_story_state(story_beats_lookup.READY_TO_TURN_IN_AXE_QUEST)
	set_dungeon_unlock(dungeon_state_lookup.FOREST_DUNGEON_UNLOCKED, true)
	set_party_member_unlock(party_member_unlock_lookup.LYRA_UNLOCKED)
	GlobalCombatInformation.add_party_member_by_character_index(party_member_unlock_lookup.LYRA_UNLOCKED, true)
	complete_speak_to_lyra_quest()

	if not has_story_state(story_beats_lookup.TURNED_IN_LYRA_QUEST):
		start_lyra_axe_quest()
		turn_in_lyra_axe_quest()
	else:
		set_dungeon_unlock(dungeon_state_lookup.FOREST_DUNGEON_UNLOCKED, true)

	story_states.erase(story_beats_lookup.SLEPT_AFTER_LYRA_QUEST)
	story_states.erase(story_beats_lookup.QUEST_BOARD_UNLOCK)

	GlobalCombatInformation.in_dungeon = false
	GlobalCombatInformation.is_combat_active = false
	Global.current_region = "Buildings_Insides"
	Global.current_location = "Buildings_Insides"
	Global.current_loading_zone = "Bedroom_Exit"
	Global.has_pending_player_spawn_position = false
	Global.pending_cutscene_path = ""
	Global.is_in_menu = false
	Global.is_paused = false
	Global.time_paused = false
	AreaStateManager.currently_transitioning = false

	if AreaStateManager.building_insides_instance == null or not is_instance_valid(AreaStateManager.building_insides_instance):
		AreaStateManager._setup(false)
	AreaStateManager.swap_scene()
	print("[Debug] Skipped to post-Lyra axe quest, before sleep.")

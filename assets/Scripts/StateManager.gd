extends Node



var story_beat_to_quest: Dictionary[int, quest] = {}

var dungeon_states: Dictionary[int, bool] = {}
var story_states: Dictionary[int, bool] = {}
var seal_completion_states: Dictionary[int, bool] = {}
var party_member_unlocked: Dictionary[int, bool] = {}
var pseduo_story_time: int = 0

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
		"loading_zone": "Bedroom",
		"required": [story_beats_lookup.READY_TO_TURN_IN_AXE_QUEST],
		"excluded": [story_beats_lookup.TURNED_IN_LYRA_QUEST]
	},
	"quest_board_unlock_cutscene": {
		"region": "Buildings_Insides",
		"loading_zone": "Tavern",
		"required": [story_beats_lookup.TURNED_IN_LYRA_QUEST], 
		"day_requirement": 3,
	},
	"cave_dungeon_entry": {
		"required": [story_beats_lookup.CAVE_DUNGEON_UNLOCKED]
	},
	"think_about_forest_clearing_mc_thought": {
		"required": [story_beats_lookup.BLACKSMITH_QUEST_FINISHED],
		"day_requirement": 5
	}
}

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

func export_to_json() -> Dictionary:
	return {
		"dungeon_states": dungeon_states,
		"story_states": story_states,
		"seal_completion_states": seal_completion_states,
		"party_member_unlocked": party_member_unlocked,
		"story_time": pseduo_story_time
	}

func load_story_states(states: Dictionary) -> void:
	dungeon_states = _convert_keys_to_int(states.get("dungeon_states", {}))
	story_states = _convert_keys_to_int(states.get("story_states", {}))
	seal_completion_states = _convert_keys_to_int(states.get("seal_completion_states", {}))
	party_member_unlocked = _convert_keys_to_int(states.get("party_member_unlocked", {}))
	pseduo_story_time = states.get("story_time", 0)

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

func set_story_state(key: int, value: bool = true) -> void:
	story_states[key] = value

func has_story_state(key: int) -> bool:
	return story_states.get(key, false)

func start_story_beat(beat: int) -> void:
	set_story_state(beat, true)
	print("[Story] Beat reached: ", beat)
	
	if story_beat_to_quest.has(beat):
		var associated_quest = story_beat_to_quest[beat]
		if associated_quest != null and is_instance_valid(GlobalCombatInformation):
			GlobalCombatInformation.add_quest(associated_quest)

func start_lyra_axe_quest() -> void:
	set_story_state(story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE)

	for existing_quest in GlobalCombatInformation.active_quests:
		if existing_quest != null and existing_quest.resource_path == LYRA_AXE_QUEST_PATH:
			print("[Story] Lyra axe quest already active.")
			GlobalCombatInformation.check_quest_progress.emit()
			return

	var lyra_quest: quest = load(LYRA_AXE_QUEST_PATH)
	if lyra_quest == null:
		push_warning("Global: Could not load Lyra axe quest: %s" % LYRA_AXE_QUEST_PATH)
		return

	GlobalCombatInformation.add_quest(lyra_quest)
	print("[Story] Started Lyra axe quest.")


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

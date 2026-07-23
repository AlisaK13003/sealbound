extends Node2D

var dist_matrix : PackedFloat32Array
var next_matrix: PackedFloat32Array

var node_count: int = 0

@export var player_node : Node2D

const LOCATION_ALIASES: Dictionary = {
	"southhouse": ["South House", "South_House", "SouthHouse", "Sout House", "Sout_House", "SoutHouse", "Orion House", "Orion_House", "OrionHouse"],
	"northhouse": ["North House", "North_House", "NorthHouse", "Kaela House", "Kaela_House", "KaelaHouse"],
	"practicefield": ["Practice Field", "Practice_Field", "PracticeField", "Practice", "Training Field", "Training_Field", "TrainingField"],
	"pondside": ["Pondside", "Pond Side", "Pond_Side", "PondSide", "Pond"],
	"taverncliff": ["Tavern Cliff", "Tavern_Cliff", "TavernCliff", "Tavern Cliffside", "Tavern_Cliffside", "TavernCliffside"],
	"herbcollecting": ["Herb Collecting", "Herb_Collecting", "HerbCollecting", "Herb Field", "Herb_Field", "HerbField"],
	"well": ["Well", "Well2", "Well Point", "Well_Point", "WellPoint"],
	"cliffside": ["Cliff Side", "Cliff_Side", "CliffSide"]
}

func _ready():
	rebuild_navigation_graph()

func rebuild_navigation_graph() -> void:
	node_count = get_child_count()
	create_adjacency_matrix()
	run_floyd_warshall()

func ensure_navigation_graph() -> void:
	if node_count != get_child_count() or dist_matrix.size() != node_count * node_count or next_matrix.size() != node_count * node_count:
		rebuild_navigation_graph()

func convert_to_int(child):
	var new_thing : Array[int]
	for thing in child.connected_node_names:
		if thing == null:
			break
		var node_name := str(thing).strip_edges()
		if node_name.is_empty():
			continue
		var connected_node := get_node_or_null(NodePath(node_name))
		if connected_node == null:
			push_warning("VillageLocationContainer: '%s' is connected to missing node '%s'." % [str(child.name), node_name])
			continue
		new_thing.append(connected_node.get_index())
	return new_thing

func create_adjacency_matrix():
	dist_matrix.resize(node_count * node_count)
	next_matrix.resize(node_count * node_count)
	for i in range(node_count):
		var current_child = get_child(i)
		var array_to_test = convert_to_int(current_child)
		for j in range(node_count):
			var distance_to_place: float = INF
			var next_idf: float = -1
			if i == j:
				distance_to_place = 0
				next_idf = j
			elif array_to_test.has(j):
				distance_to_place = (current_child.location_position[2].distance_to(get_child(j).location_position[2]))
				next_idf = j
			else:
				next_idf = -1
			dist_matrix[i * node_count + j] = distance_to_place
			next_matrix[i * node_count + j] = next_idf
			
func run_floyd_warshall():
	var n = node_count
	for k in range(n):
		for i in range(n):
			for j in range(n):
				var ik = i * n + k
				var kj = k * n + j
				var ij = i * n + j
				
				if dist_matrix[ik] + dist_matrix[kj] < dist_matrix[ij]:
					dist_matrix[ij] = dist_matrix[ik] + dist_matrix[kj]
					next_matrix[ij] = next_matrix[ik]
					
# Given start location and end location, returns path to traverse to get between them.
# Schedules can use child indexes or child node names from this container.
func get_location_index(location) -> int:
	match typeof(location):
		TYPE_INT:
			return location
		TYPE_FLOAT:
			return int(location)
		TYPE_STRING:
			var location_name = str(location).strip_edges()
			if location_name.is_empty():
				return -1
			
			var location_node = get_node_or_null(NodePath(location_name))
			if location_node != null:
				return location_node.get_index()
			var numeric_index: int = -1
			if location_name.is_valid_int():
				numeric_index = int(location_name)
			var normalized_location_name = normalize_location_name(location_name)
			var normalized_index = get_location_index_by_normalized_name(normalized_location_name)
			if normalized_index >= 0:
				return normalized_index
			var numbered_name_index = get_location_index_by_numeric_suffix(normalized_location_name)
			if numbered_name_index >= 0:
				return numbered_name_index
			if LOCATION_ALIASES.has(normalized_location_name):
				for alias in LOCATION_ALIASES[normalized_location_name]:
					var alias_index = get_location_index_by_normalized_name(normalize_location_name(str(alias)))
					if alias_index >= 0:
						return alias_index
			if numeric_index >= 0:
				return numeric_index

	push_warning("VillageLocationContainer: Could not find schedule location '%s'." % str(location))
	return -1

func get_location_index_by_normalized_name(normalized_location_name: String) -> int:
	for child in get_children():
		if normalize_location_name(str(child.name)) == normalized_location_name:
			return child.get_index()
	return -1

func get_location_index_by_numeric_suffix(normalized_location_name: String) -> int:
	if not normalized_location_name.is_valid_int():
		return -1
	for child in get_children():
		var normalized_child_name = normalize_location_name(str(child.name))
		var suffix_start = normalized_child_name.length() - normalized_location_name.length()
		if suffix_start < 0:
			continue
		if normalized_child_name.substr(suffix_start) != normalized_location_name:
			continue
		if suffix_start == 0:
			return child.get_index()
		var previous_character = normalized_child_name.substr(suffix_start - 1, 1)
		if not previous_character.is_valid_int():
			return child.get_index()
	return -1

func normalize_location_name(location_name: String) -> String:
	return location_name.to_lower().replace(" ", "").replace("_", "").replace("-", "")

func get_path_between(start_spot, end_spot) -> Array[int]:
	ensure_navigation_graph()
	var start_id = get_location_index(start_spot)
	var end_id = get_location_index(end_spot)
	if start_id < 0 or end_id < 0 or start_id >= node_count or end_id >= node_count:
		return []
	if start_id == end_id:
		return [start_id]
	if next_matrix[start_id * node_count + end_id] == -1:
		return []
	
	var path: Array[int] = [start_id]
	while start_id != end_id:
		start_id = int(next_matrix[start_id * node_count + end_id])
		path.append(start_id)
	return path

func begin_teleportation():
	player_node.fade_in()
	pass

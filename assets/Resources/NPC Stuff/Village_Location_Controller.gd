extends Node2D

var dist_matrix : PackedFloat32Array
var next_matrix: PackedFloat32Array

@onready var node_count = get_child_count()

@export var player_node : Node2D

func _ready():
	create_adjacency_matrix()
	run_floyd_warshall()

func convert_to_int(child):
	var new_thing : Array[int]
	for thing in child.connected_node_names:
		if thing == null:
			break
		new_thing.append(self.get_node(thing).get_index())
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
			if location_name.is_valid_int():
				return int(location_name)
			var location_node = get_node_or_null(NodePath(location_name))
			if location_node != null:
				return location_node.get_index()

	push_warning("VillageLocationContainer: Could not find schedule location '%s'." % str(location))
	return -1

func get_path_between(start_spot, end_spot) -> Array[int]:
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
		start_id = next_matrix[start_id * node_count + end_id]
		path.append(start_id)
	return path

func begin_teleportation():
	player_node.fade_in()
	pass

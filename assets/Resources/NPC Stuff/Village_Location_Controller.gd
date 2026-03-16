extends Node2D

@export var node_names : Dictionary = {}

@onready var node_count = get_child_count()

var dist_matrix : PackedFloat32Array
var next_matrix: PackedFloat32Array

func _ready():
	create_adjacency_matrix()
	run_floyd_warshall()
	
func create_adjacency_matrix():
	dist_matrix.resize(node_count * node_count)
	next_matrix.resize(node_count * node_count)
	for i in range(node_count):
		var current_child = get_child(i)
		print(current_child.location_name, ": ", current_child.location_position[2])
		for j in range(node_count):
			var distance_to_place: float = INF
			var next_idf: float = -1
			if i == j:
				distance_to_place = 0
				next_idf = j
			elif current_child.connected_to_places.has(j):
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
				
				# If path through k is shorter than current path
				if dist_matrix[ik] + dist_matrix[kj] < dist_matrix[ij]:
					dist_matrix[ij] = dist_matrix[ik] + dist_matrix[kj]
					# Update the path to go through the same first step as i to k
					next_matrix[ij] = next_matrix[ik]
					

# This helper function reconstructs the list of node IDs for the NPC to follow
func get_path_between(start_id: int, end_id: int) -> Array[int]:
	if next_matrix[start_id * node_count + end_id] == -1:
		return [] # No path exists
	
	var path: Array[int] = [start_id]
	while start_id != end_id:
		start_id = next_matrix[start_id * node_count + end_id]
		path.append(start_id)
	return path

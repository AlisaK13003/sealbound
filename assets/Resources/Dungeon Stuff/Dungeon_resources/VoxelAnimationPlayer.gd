extends MeshInstance3D
class_name AnimatedMeshPlayer

var current_animation
@export var playing: bool = true

var current_frame: int = 0
var time_passed: float = 0.0
var cached_meshes: Array[Mesh] = []

func _setup(current_animation_: voxel_animation) -> void:
	current_animation = current_animation_
	print("Playing")
	extract_and_cache_meshes()
	if cached_meshes.size() > 0:
		mesh = cached_meshes[0]

func extract_and_cache_meshes() -> void:
	cached_meshes.clear()
	if not current_animation:
		return
	
	for res in current_animation.frames:
		if res is PackedScene: 
			var inst = res.instantiate()
			var found_mesh: Mesh = null
			
			if inst is MeshInstance3D:
				found_mesh = inst.mesh
				if found_mesh.do_flip_h:
					print("HI")
					found_mesh.flip_h = true
				elif found_mesh.do_flip_v:
					found_mesh.flip_v = true
			else:
				for child in inst.get_children():
					if child is MeshInstance3D:
						found_mesh = child.mesh

						break
			
			if found_mesh:
				cached_meshes.append(found_mesh)
			else:
				push_warning("Could not find a MeshInstance3D inside " + res.resource_path)
			
			inst.free()

func _process(delta: float) -> void:
	if not playing or cached_meshes.size() == 0:
		return
	
	time_passed += delta
	var frame_time = 1.0 / current_animation.fps
	
	if time_passed >= frame_time:
		time_passed -= frame_time
		
		current_frame += 1
		if current_frame >= cached_meshes.size():
			if current_animation.loop:
				current_frame = 0
			else:
				current_frame = cached_meshes.size() - 1
				playing = false
				
		mesh = cached_meshes[current_frame]

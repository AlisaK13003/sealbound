extends Resource

class_name voxel_animation

@export var anim_name: String
@export var frames: Array[PackedScene] = []
@export var fps: float = 10.0
@export var do_flip_h: bool = true
@export var do_flip_v: bool = true
@export var loop: bool = true

extends Camera2D

@export var target: Node2D
@export_range(0.0, 1.0) var lerp_weight: float = 0.1
@export var overshoot: Vector2 = Vector2(2.0, 2.0)

var cam_pos: Vector2

func _ready() -> void:
	if target:
		cam_pos = target.global_position
		global_position = cam_pos

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	var weight = clamp(lerp_weight * delta * 60.0, 0.0, 1.0)
	cam_pos = lerp_overshoot_v(cam_pos, target.global_position, weight, overshoot)
	
	global_position = cam_pos.round()


static func lerp_overshoot(from: float, to: float, weight: float, overshoot_val: float) -> float:
	var d := (to - from) * weight
	
	if is_equal_approx(d, 0.0):
		return to
	
	var s = sign(d)
	var l: float = lerp(from, to + (overshoot_val * s), weight)
	
	if s == 1.0:
		l = min(l, to)
	elif s == -1.0:
		l = max(l, to)
	
	return l

static func lerp_overshoot_v(from: Vector2, to: Vector2, weight: float, overshoot_vec: Vector2) -> Vector2:
	var x = lerp_overshoot(from.x, to.x, weight, overshoot_vec.x)
	var y = lerp_overshoot(from.y, to.y, weight, overshoot_vec.y)
	
	return Vector2(x, y)

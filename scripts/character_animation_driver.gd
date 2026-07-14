class_name CharacterAnimationDriver
extends RefCounted

var facing_left: bool = false
var facing_direction: StringName = &"down"

func sync(sprite: AnimatedSprite2D, motion: Vector2) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	if motion.length_squared() < 0.0001:
		_play_idle_for_facing(sprite)
		return

	if abs(motion.x) > abs(motion.y):
		facing_left = motion.x < 0
		facing_direction = &"side"
		sprite.flip_h = facing_left
		_play_if_available(sprite, "walk_side", ["walk"])
		return

	sprite.flip_h = facing_left
	if motion.y < 0:
		facing_direction = &"up"
		_play_if_available(sprite, "walk_up", ["walk"])
	else:
		facing_direction = &"down"
		_play_if_available(sprite, "walk_down", ["walk"])

func _play_idle_for_facing(sprite: AnimatedSprite2D) -> void:
	sprite.flip_h = facing_left

	var candidates = [&"idle_down", &"idle", &"walk_down", &"walk"]
	if facing_direction == &"up":
		candidates = [&"idle_up", &"walk_up", &"idle", &"walk"]
	elif facing_direction == &"side":
		candidates = [&"idle_side", &"walk_side", &"idle", &"walk"]

	for animation_name in candidates:
		if not sprite.sprite_frames.has_animation(animation_name):
			continue
		if String(animation_name).begins_with("walk"):
			_play_frozen_pose(sprite, animation_name, 1 if facing_direction == &"side" else 0)
		else:
			_play_if_available(sprite, animation_name)
		return

func _play_if_available(sprite: AnimatedSprite2D, animation_name: StringName, fallbacks: Array[StringName] = []) -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		for fallback_name in fallbacks:
			if sprite.sprite_frames.has_animation(fallback_name):
				animation_name = fallback_name
				break
		if not sprite.sprite_frames.has_animation(animation_name):
			return
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _play_frozen_pose(sprite: AnimatedSprite2D, animation_name: StringName, pose_frame: int = 0) -> void:
	if sprite.animation != animation_name or sprite.is_playing():
		sprite.play(animation_name)
		sprite.frame = mini(pose_frame, sprite.sprite_frames.get_frame_count(animation_name) - 1)
		sprite.frame_progress = 0.0
	sprite.pause()

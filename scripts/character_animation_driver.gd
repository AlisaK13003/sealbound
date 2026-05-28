class_name CharacterAnimationDriver
extends RefCounted

var facing_left: bool = false

func sync(sprite: AnimatedSprite2D, motion: Vector2) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	if motion.length_squared() < 0.0001:
		_play_if_available(sprite, "idle", ["walk"])
		sprite.flip_h = facing_left
		return

	if abs(motion.x) > abs(motion.y):
		facing_left = motion.x < 0
		sprite.flip_h = facing_left
		_play_if_available(sprite, "walk_side", ["walk"])
		return

	sprite.flip_h = facing_left
	if motion.y < 0:
		_play_if_available(sprite, "walk_up", ["walk"])
	else:
		_play_if_available(sprite, "walk_down", ["walk"])

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
	if sprite.animation != animation_name:
		sprite.play(animation_name)

class_name CharacterAnimationDriver
extends RefCounted

var facing_left: bool = false

func setup_sprite(
	animated_sprite: AnimatedSprite2D,
	idle_texture: Texture2D,
	walk_texture: Texture2D = null,
	idle_frame_size: Vector2i = Vector2i.ZERO,
	walk_frame_size: Vector2i = Vector2i.ZERO,
	walk_frames_per_row: int = 0,
	walk_down_row: int = 0,
	walk_side_row: int = 1,
	walk_up_row: int = 2,
	animation_speed: float = 8.0
) -> void:
	if animated_sprite == null:
		return

	var sprite_frames := SpriteFrames.new()

	if idle_texture != null:
		_add_single_frame_animation(sprite_frames, "idle", idle_texture, idle_frame_size, animation_speed)

	if walk_texture != null and walk_frame_size.x > 0 and walk_frame_size.y > 0 and walk_frames_per_row > 0:
		_add_sheet_animation(sprite_frames, "walk_down", walk_texture, walk_frame_size, walk_frames_per_row, walk_down_row, animation_speed)
		_add_sheet_animation(sprite_frames, "walk_side", walk_texture, walk_frame_size, walk_frames_per_row, walk_side_row, animation_speed)
		_add_sheet_animation(sprite_frames, "walk_up", walk_texture, walk_frame_size, walk_frames_per_row, walk_up_row, animation_speed)

	animated_sprite.sprite_frames = sprite_frames
	if sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func sync(sprite: AnimatedSprite2D, motion: Vector2) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	if motion.length_squared() < 0.0001:
		_play_if_available(sprite, "idle")
		sprite.flip_h = facing_left
		return

	if abs(motion.x) > abs(motion.y):
		facing_left = motion.x < 0
		sprite.flip_h = facing_left
		_play_if_available(sprite, "walk_side")
		return

	sprite.flip_h = facing_left
	if motion.y < 0:
		_play_if_available(sprite, "walk_up")
	else:
		_play_if_available(sprite, "walk_down")

func _play_if_available(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		if sprite.sprite_frames.has_animation("idle"):
			animation_name = "idle"
		else:
			return
	if sprite.animation != animation_name:
		sprite.play(animation_name)

func _add_single_frame_animation(sprite_frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_size: Vector2i, animation_speed: float) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, animation_speed)

	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	if frame_size.x > 0 and frame_size.y > 0:
		atlas_texture.region = Rect2(Vector2.ZERO, frame_size)
	else:
		atlas_texture.region = Rect2(Vector2.ZERO, texture.get_size())
	sprite_frames.add_frame(animation_name, atlas_texture)

func _add_sheet_animation(sprite_frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_size: Vector2i, frames_per_row: int, row_index: int, animation_speed: float) -> void:
	if frames_per_row <= 0:
		return

	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, animation_speed)

	for frame_index in frames_per_row:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(Vector2(frame_index * frame_size.x, row_index * frame_size.y), frame_size)
		sprite_frames.add_frame(animation_name, atlas_texture)
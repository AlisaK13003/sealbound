class_name Player extends CharacterBody2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")

var in_menu : bool = false
@export var move_speed : float = 300.0


@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var over_the_head_sprite = $OvertheHead
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var camera_zoom: Vector2 = Vector2(1, 1)
@export var female_idle_texture: Texture2D = preload("res://assets/characters/player/female_idle.png")
@export var female_walk_texture: Texture2D = preload("res://assets/characters/player/female_walk.png")
@export var male_idle_texture: Texture2D = preload("res://assets/characters/player/male_idle.png")
@export var male_walk_texture: Texture2D = preload("res://assets/characters/player/male_walk.png")

var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()
var tutorial_label: Label

func _ready() -> void:
	if Global.loading_from_save:
		global_position = Global.saved_position
		Global.loading_from_save = false
	apply_gender_sprite()
	var identity_changed_callback = Callable(self, "apply_gender_sprite")
	if not Global.player_identity_changed.is_connected(identity_changed_callback):
		Global.player_identity_changed.connect(identity_changed_callback)
	_setup_tutorial_label()
	$Camera2D.reset_smoothing()
	animation_driver.sync(animated_sprite, Vector2.ZERO)
	$Camera2D.zoom = camera_zoom
	pause_menu.visible = false
	if not Global.pending_cutscene_path.is_empty():
		call_deferred("_play_pending_cutscene")

func _process(_delta: float) -> void:
	_update_tutorial_label()
	var direction : Vector2 = Vector2.ZERO
	if Global.is_in_menu or Fade.is_fading or AreaStateManager.currently_transitioning or Global.is_paused:
		velocity = Vector2.ZERO
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
	#direction = Input.get_vector("left", "right", "up", "down")

	if not Global.using_controller:
		direction = Input.get_vector("left", "right", "up", "down")
	else:
		direction = Input.get_vector(Global.controller_mapping["left"], Global.controller_mapping["right"], Global.controller_mapping["up"], Global.controller_mapping["down"])
		
	velocity = direction * move_speed
	animation_driver.sync(animated_sprite, velocity)
	
	if Global.player_head_sprite != null:
		over_the_head_sprite.texture = Global.player_head_sprite
	else:
		over_the_head_sprite.texture = null
	
func _input(event):
	# In Player _input
	if Global.get_input_mapping("Pause") and not Global.cant_leave_menu:
		if not pause_menu.visible:
			if Global.is_in_menu:
				return
			AudioManager.play_ui_sound(AudioManager.MENU_OPEN)
			AudioManager.stop_bgm()
			Global.menu_opened.emit()
			Global.is_paused = true
			pause_menu.visible = true
			get_tree().paused = true
			in_menu = true
			#full_inventory.manage_visibility(false)
			get_viewport().set_input_as_handled()
			pause_menu._reset()
		else:
			AudioManager.play_ui_sound(AudioManager.MENU_CLOSE)
			AudioManager.restart_bgm()
			Global.menu_closed.emit()
			Global.is_paused = false
			get_tree().paused = false
			in_menu = false
			pause_menu.visible = false
			pause_menu._reset()
	return

	
func _physics_process(_delta):
	move_and_slide()

func _play_pending_cutscene() -> void:
	var cutscene_path = Global.pending_cutscene_path
	Global.pending_cutscene_path = ""
	var runner = CUTSCENE_RUNNER_SCRIPT.new()
	get_tree().current_scene.add_child(runner)
	runner.finished.connect(runner.queue_free)
	runner.play(cutscene_path)

func apply_gender_sprite() -> void:
	if animated_sprite == null:
		return
	var idle_texture = female_idle_texture
	var walk_texture = female_walk_texture
	if Global.player_gender == "male":
		idle_texture = male_idle_texture
		walk_texture = male_walk_texture
	animated_sprite.sprite_frames = _build_overworld_sprite_frames(idle_texture, walk_texture)
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func _build_overworld_sprite_frames(idle_texture: Texture2D, walk_texture: Texture2D) -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 5.0)
	frames.add_frame("idle", _atlas_frame(idle_texture, Rect2(0, 0, 192, 288)))
	_add_walk_animation(frames, "walk_down", walk_texture, [0, 1, 2, 3], 5.0)
	_add_walk_animation(frames, "walk_up", walk_texture, [4, 5, 6, 7], 7.0)
	_add_walk_animation(frames, "walk_side", walk_texture, [8, 9, 10, 11], 5.0)
	return frames

func _add_walk_animation(frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_indexes: Array[int], speed: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, speed)
	for frame_index in frame_indexes:
		frames.add_frame(animation_name, _atlas_frame(texture, Rect2(frame_index * 192, 0, 192, 288)))

func _atlas_frame(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = region
	return atlas_texture

func _setup_tutorial_label() -> void:
	tutorial_label = Label.new()
	tutorial_label.visible = false
	tutorial_label.position = Vector2(24, 72)
	tutorial_label.custom_minimum_size = Vector2(520, 0)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_font_size_override("font_size", 18)
	$CanvasLayer.add_child(tutorial_label)

func _update_tutorial_label() -> void:
	if tutorial_label == null:
		return
	tutorial_label.text = Global.current_tutorial_objective
	tutorial_label.visible = not Global.current_tutorial_objective.is_empty()

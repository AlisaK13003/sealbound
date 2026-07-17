class_name Player extends CharacterBody2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")
const OVERWORLD_SPRITE_DISPLAY_HEIGHT: float = 39.0

var in_menu : bool = false
@export var move_speed : float = 300.0

@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var over_the_head_sprite = $OvertheHead
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var female_idle_texture: Texture2D = preload("res://assets/characters/player/female_idle.png")
@export var female_walk_texture: Texture2D = preload("res://assets/characters/player/female_walk.png")
@export var male_idle_texture: Texture2D = preload("res://assets/characters/player/male_idle.png")
@export var male_walk_texture: Texture2D = preload("res://assets/characters/player/male_walk.png")

@export var male_sprite_frames: SpriteFrames
@export var female_sprite_frames: SpriteFrames

@export var walking_on_dirt: Array[AudioStream]
@export var walking_on_sand_gravel: Array[AudioStream]
@export var walking_on_stone: Array[AudioStream]
@export var walking_on_wood: Array[AudioStream]

var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()
var tutorial_label: Label

@export var step_interval: float = 36.0
var distance_walked: float = 0.0
var inside = false

func _ready() -> void:
	if Global.loading_from_save:
		global_position = Global.saved_position
		Global.loading_from_save = false
	apply_gender_sprite()
	var identity_changed_callback = Callable(self, "apply_gender_sprite")
	if not Global.player_identity_changed.is_connected(identity_changed_callback):
		Global.player_identity_changed.connect(identity_changed_callback)
	_setup_tutorial_label()
	
	animation_driver.sync(animated_sprite, Vector2.ZERO)
	pause_menu.visible = false
	if not Global.pending_cutscene_path.is_empty():
		call_deferred("_play_pending_cutscene")
	Global.day_passed.connect(_pass_out)

var transitioning_day: bool = false
func _pass_out(did_pass_out):
	transitioning_day = true
	if did_pass_out:
		animated_sprite.play("ow_passout")
		print("you passed out")
		await animated_sprite.animation_finished
		Global.current_region = "Buildings_Insides"
		Global.current_loading_zone = "Bedspawn"
		var building_scene = AreaStateManager.building_insides_instance

		var mc_marker: Marker2D = _find_marker_by_names(building_scene, ["Scene1_MCSpawn", "Scene1_MC_Spawn"])
		
		await Fade.fade_in(1.0)
		AreaStateManager.swap_scene(get_tree().current_scene)
		await Fade.fade_out(2.0)
	else:
		pass
	transitioning_day = false

func _find_marker_by_names(root: Node, marker_names: Array) -> Marker2D:
	for marker_name in marker_names:
		var marker: Marker2D = root.find_child(str(marker_name), true, false) as Marker2D
		if marker != null:
			return marker
	return null

func _process(_delta: float) -> void:
	_update_tutorial_label()
	
	if Global.player_head_sprite != null:
		over_the_head_sprite.texture = Global.player_head_sprite
	else:
		over_the_head_sprite.texture = null

func _physics_process(_delta: float) -> void:
	if transitioning_day:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if Global.is_in_menu or Fade.is_fading or AreaStateManager.currently_transitioning or Global.is_paused:
		velocity = Vector2.ZERO
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		move_and_slide()
		return

	var direction : Vector2 = Vector2.ZERO
	if not Global.using_controller:
		direction = Input.get_vector("left", "right", "up", "down")
	else:
		direction = Input.get_vector(Global.controller_mapping["left"], Global.controller_mapping["right"], Global.controller_mapping["up"], Global.controller_mapping["down"])
		
	velocity = direction * move_speed
	
	var anim_velocity = velocity
	if velocity.x != 0:
		anim_velocity.y = 0
	
	animation_driver.sync(animated_sprite, anim_velocity)
	
	move_and_slide()
	
	var is_moving = velocity.length() > 10.0
	if is_moving:
		distance_walked += velocity.length() * _delta
		if distance_walked >= step_interval:
			_play_footstep_sound()
			distance_walked = 0.0

func _play_footstep_sound() -> void:
	var current_terrain = get_terrain_under_feet()
	if not inside:
		match current_terrain:
			0: AudioManager.play_tile_sound(walking_on_dirt.pick_random())
			1, 2: AudioManager.play_tile_sound(walking_on_sand_gravel.pick_random())
			3: AudioManager.play_tile_sound(walking_on_wood.pick_random())
			4: AudioManager.play_tile_sound(walking_on_stone.pick_random())
	else:
		match current_terrain:
			0, 2: AudioManager.play_tile_sound(walking_on_wood.pick_random())

func get_terrain_under_feet() -> int:
	var floor_layers = get_tree().get_nodes_in_group("Ground")
	if floor_layers.is_empty():
		floor_layers = get_tree().get_nodes_in_group("Building_Ground")
		if floor_layers.is_empty():
			return -1
		inside = true
	else:
		inside = false
		
	floor_layers.sort_custom(func(a: Node, b: Node) -> bool:
		if a.z_index != b.z_index:
			return a.z_index > b.z_index
		return a.get_index() > b.get_index()
	)

	for layer in floor_layers:
		if layer is TileMapLayer:
			var local_pos = layer.to_local(global_position)
			var map_pos = layer.local_to_map(local_pos)
			var tile_data = layer.get_cell_tile_data(map_pos)
			if tile_data and tile_data.terrain != -1:
				return tile_data.terrain
	return -1

func _input(event):
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
	var display_scale: float = OVERWORLD_SPRITE_DISPLAY_HEIGHT / float(walk_texture.get_height())
	animated_sprite.scale = Vector2(display_scale, display_scale)
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func _build_overworld_sprite_frames(idle_texture: Texture2D, walk_texture: Texture2D) -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var walk_frame_width: int = int(walk_texture.get_width() / 12.0)
	var walk_frame_height: int = int(walk_texture.get_height())
	var idle_frame_width: int = mini(int(idle_texture.get_width()), walk_frame_width)
	var idle_frame_x: int = maxi(0, int((idle_texture.get_width() - idle_frame_width) / 2.0))

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 5.0)
	frames.add_frame("idle", _atlas_frame(idle_texture, Rect2(idle_frame_x, 0, idle_frame_width, idle_texture.get_height())))
	_add_walk_animation(frames, "walk_down", walk_texture, [0, 1, 2, 3], 5.0, Vector2i(walk_frame_width, walk_frame_height))
	_add_walk_animation(frames, "walk_up", walk_texture, [4, 5, 6, 7], 7.0, Vector2i(walk_frame_width, walk_frame_height))
	_add_walk_animation(frames, "walk_side", walk_texture, [8, 9, 10, 11], 5.0, Vector2i(walk_frame_width, walk_frame_height))
	return frames

func _add_walk_animation(frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_indexes: Array[int], speed: float, frame_size: Vector2i) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, speed)
	for frame_index in frame_indexes:
		frames.add_frame(animation_name, _atlas_frame(texture, Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)))

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

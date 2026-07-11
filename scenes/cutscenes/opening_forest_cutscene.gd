extends Node2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")
const OPENING_CUTSCENE_PATH = "res://assets/Resources/Cutscenes/opening_tutorial.json"
const INFIRMARY_WAKEUP_CUTSCENE_PATH = "res://assets/Resources/Cutscenes/infirmary_wakeup.json"
const INFIRMARY_FALLBACK_PLAYER_POSITION = Vector2(2302, -749)
const SCENE1_MC_MARKER_NAMES = ["Scene1_MCSpawn", "Scene1_MC_Spawn"]
const SCENE1_SERA_MARKER_NAMES = ["Scene1_SeraSpawn", "Scene1_Sera_Spawn"]
const SCENE1_SERA_NODE_NAME = "Sera_NPC"

@onready var mc: AnimatedSprite2D = $Actors/MC
@onready var shadow: AnimatedSprite2D = $Actors/ShadowyFigure
@onready var sera: AnimatedSprite2D = $Actors/Sera
@onready var lantern_light: PointLight2D = $Actors/Sera/LanternLight
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shadow_start: Marker2D = $Markers/Shadow_Start
@onready var shadow_close: Marker2D = $Markers/Shadow_Close
@onready var shadow_exit: Marker2D = $Markers/Shadow_Exit
@onready var sera_start: Marker2D = $Markers/Sera_Start
@onready var sera_mc_side: Marker2D = $Markers/Sera_MCSide

var shadow_marker_offset := Vector2.ZERO
var sera_marker_offset := Vector2.ZERO
var lantern_flicker_time := 0.0
var lantern_base_energy := 0.85

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_marker_offsets()
	_apply_initial_actor_state()
	call_deferred("_start_cutscene")

func _process(delta: float) -> void:
	if lantern_light == null or not lantern_light.visible:
		return
	lantern_flicker_time += delta * 8.0
	lantern_light.energy = lantern_base_energy + sin(lantern_flicker_time) * 0.05 + sin(lantern_flicker_time * 2.1) * 0.025

func play_cutscene_animation(animation_name: String):
	var clip_name = _animation_clip_name(animation_name)
	if animation_player.has_animation(clip_name):
		if clip_name.begins_with("sera_"):
			sera.visible = true
			_show_lantern()
		animation_player.play(clip_name)
		return animation_player.animation_finished

	match animation_name:
		"shadow_approaches":
			return _move_actor_to_marker(shadow, shadow_close, shadow_marker_offset, 0.9)
		"shadow_runs_away":
			return _move_actor_to_marker(shadow, shadow_exit, shadow_marker_offset, 1.1, true)
		"sera_approaches_mc":
			sera.visible = true
			_show_lantern()
			var start_position = sera_start.global_position + sera_marker_offset
			var target_position = start_position.lerp(_sera_mc_side_position(), 0.48)
			sera.global_position = start_position
			return _move_actor_to_position(sera, target_position, 1.25)
		"sera_runs_to_mc":
			sera.visible = true
			_show_lantern()
			return _move_actor_to_position(sera, _sera_mc_side_position(), 0.65)
	return null

func _animation_clip_name(animation_name: String) -> String:
	match animation_name:
		"shadow_approaches":
			return "shadow_approach"
		"shadow_runs_away":
			return "shadow_exit"
		"sera_approaches_mc":
			return "sera_approach"
		"sera_runs_to_mc":
			return "sera_run"
		_:
			return animation_name

func _cache_marker_offsets() -> void:
	shadow_marker_offset = shadow.global_position - shadow_start.global_position
	sera_marker_offset = sera.global_position - sera_start.global_position

func _apply_initial_actor_state() -> void:
	if Global.player_gender == "male" and mc.sprite_frames.has_animation("idle_male"):
		mc.animation = &"idle_male"
	elif mc.sprite_frames.has_animation("idle_female"):
		mc.animation = &"idle_female"

	shadow.global_position = shadow_start.global_position + shadow_marker_offset
	shadow.visible = true
	_set_actor_animation(shadow, "idle")

	sera.global_position = sera_start.global_position + sera_marker_offset
	sera.visible = false
	_set_actor_animation(sera, "idle")
	lantern_light.visible = false
	lantern_light.energy = 0.0

func _start_cutscene() -> void:
	var cutscene_runner = CUTSCENE_RUNNER_SCRIPT.new()
	cutscene_runner.finished.connect(_on_opening_cutscene_finished)
	cutscene_runner.finished.connect(cutscene_runner.queue_free)
	add_child(cutscene_runner)
	cutscene_runner.play(OPENING_CUTSCENE_PATH)

func _on_opening_cutscene_finished() -> void:
	Global.pending_cutscene_path = INFIRMARY_WAKEUP_CUTSCENE_PATH
	Global.current_region = "Buildings_Insides"
	Global.current_loading_zone = "Infirmary"
	AreaStateManager._setup()
	_prepare_infirmary_wakeup_positions()
	AreaStateManager.swap_scene(self)


func _prepare_infirmary_wakeup_positions() -> void:
	var building_scene = AreaStateManager.building_insides_instance
	if building_scene == null:
		Global.set_pending_player_spawn_position(INFIRMARY_FALLBACK_PLAYER_POSITION)
		return

	var mc_marker := _find_marker_by_names(building_scene, SCENE1_MC_MARKER_NAMES)
	if mc_marker != null:
		Global.set_pending_player_spawn_position(mc_marker.global_position)
	else:
		push_warning("Scene1 MC spawn marker not found. Using fallback infirmary position.")
		Global.set_pending_player_spawn_position(INFIRMARY_FALLBACK_PLAYER_POSITION)

	var sera_marker := _find_marker_by_names(building_scene, SCENE1_SERA_MARKER_NAMES)
	if sera_marker == null:
		push_warning("Scene1 Sera spawn marker not found.")
		return

	var sera_node := building_scene.find_child(SCENE1_SERA_NODE_NAME, true, false) as Node2D
	if sera_node == null:
		push_warning("Scene1 Sera NPC not found in Building Insides scene.")
		return

	sera_node.global_position = sera_marker.global_position


func _find_marker_by_names(root: Node, marker_names: Array) -> Marker2D:
	for marker_name in marker_names:
		var marker := root.find_child(str(marker_name), true, false) as Marker2D
		if marker != null:
			return marker
	return null

func _move_actor_to_marker(actor: AnimatedSprite2D, marker: Marker2D, marker_offset: Vector2, duration: float, hide_after := false) -> Signal:
	return _move_actor_to_position(actor, marker.global_position + marker_offset, duration, hide_after)

func _move_actor_to_position(actor: AnimatedSprite2D, target_position: Vector2, duration: float, hide_after := false) -> Signal:
	var direction = target_position - actor.global_position
	if abs(direction.x) > 0.01:
		actor.flip_h = direction.x < 0.0
	_set_actor_animation(actor, "walk_side")

	var tween = create_tween()
	tween.tween_property(actor, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_actor_move_finished.bind(actor, hide_after))
	return tween.finished

func _on_actor_move_finished(actor: AnimatedSprite2D, hide_after: bool) -> void:
	if hide_after:
		actor.visible = false
	else:
		_set_actor_animation(actor, "idle")

func _set_actor_animation(actor: AnimatedSprite2D, animation_name: String) -> void:
	if actor.sprite_frames != null and actor.sprite_frames.has_animation(animation_name):
		actor.play(animation_name)

func _show_lantern() -> void:
	if lantern_light.visible:
		return
	lantern_light.visible = true
	lantern_light.energy = 0.0
	var tween = create_tween()
	tween.tween_property(lantern_light, "energy", lantern_base_energy, 0.35)

func _sera_mc_side_position() -> Vector2:
	return sera_mc_side.global_position + sera_marker_offset

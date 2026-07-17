extends CanvasLayer

signal finished

const ATTACK_ANIMATION := &"On_Attack_Base"
const IDLE_ANIMATION := &"Idle"
const WALK_RIGHT_ANIMATION := &"Walk_Right"
const DEFAULT_ATTACK_DURATION := 0.35
const DEFAULT_SPRITE_SCALE := Vector2(2.4, 2.4)

@onready var party_sprites: Array[AnimatedSprite2D] = [
	$AttackActors/PartySprite1,
	$AttackActors/PartySprite2,
	$AttackActors/PartySprite3
]
@onready var slash_sprites: Array[AnimatedSprite2D] = [
	$SlashEffects/Slash1,
	$SlashEffects/Slash2,
	$SlashEffects/Slash3
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sprite in party_sprites:
		sprite.visible = false
	for slash in slash_sprites:
		slash.visible = false


func play_attack(party_nodes: Array, target_nodes) -> void:
	var target_position := _get_target_position(target_nodes)
	var attackers := _get_living_party_nodes(party_nodes)
	var tasks: Array[Callable] = []

	for i in range(party_sprites.size()):
		var sprite := party_sprites[i]
		if i >= attackers.size():
			sprite.visible = false
			continue

		var attacker = attackers[i]
		var start_position := _screen_position_for_node(attacker, _fallback_party_position(i))
		var strike_position := target_position + Vector2(-50.0, -34.0 + (34.0 * i))
		tasks.append(Callable(self, "_play_single_attacker").bind(sprite, attacker, start_position, strike_position, i))

	await _await_parallel(tasks)
	finished.emit()
	queue_free()


func _play_single_attacker(sprite: AnimatedSprite2D, attacker, start_position: Vector2, strike_position: Vector2, index: int) -> void:
	if attacker == null or attacker.stored_combatant == null:
		sprite.visible = false
		return

	var combatant = attacker.stored_combatant
	sprite.sprite_frames = combatant.sprite_frames
	sprite.offset = combatant.sprite_offset
	sprite.scale = DEFAULT_SPRITE_SCALE
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	sprite.position = start_position
	sprite.visible = true

	_play_best_available(sprite, WALK_RIGHT_ANIMATION)
	await get_tree().create_timer(0.08 * index).timeout

	var rush_tween := create_tween()
	rush_tween.tween_property(sprite, "position", strike_position, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await rush_tween.finished

	_play_slash(index, strike_position + Vector2(28.0, -10.0))
	_play_best_available(sprite, ATTACK_ANIMATION)
	await get_tree().create_timer(DEFAULT_ATTACK_DURATION).timeout

	var retreat_tween := create_tween()
	retreat_tween.tween_property(sprite, "position", start_position, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await retreat_tween.finished

	sprite.visible = false


func _play_slash(index: int, position: Vector2) -> void:
	if index >= slash_sprites.size():
		return

	var slash := slash_sprites[index]
	if slash.sprite_frames == null:
		return

	slash.position = position
	slash.visible = true
	_play_best_available(slash, ATTACK_ANIMATION)

	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.2)
	await tween.finished
	slash.modulate.a = 1.0
	slash.visible = false


func _play_best_available(sprite: AnimatedSprite2D, preferred_animation: StringName) -> void:
	if sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(preferred_animation):
		sprite.play(preferred_animation)
	elif sprite.sprite_frames.has_animation(IDLE_ANIMATION):
		sprite.play(IDLE_ANIMATION)


func _get_living_party_nodes(party_nodes: Array) -> Array:
	var living_party := []
	for node in party_nodes:
		if node == null or not is_instance_valid(node):
			continue
		if not node.visible:
			continue
		if node.stored_combatant == null or node.stored_combatant.is_dead:
			continue
		living_party.append(node)
	return living_party


func _get_target_position(target_nodes) -> Vector2:
	var targets := []
	if target_nodes is Array:
		targets = target_nodes
	elif target_nodes != null:
		targets = [target_nodes]

	var total_position := Vector2.ZERO
	var valid_target_count := 0
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		total_position += _screen_position_for_node(target, _fallback_target_position())
		valid_target_count += 1

	if valid_target_count == 0:
		return _fallback_target_position()
	return total_position / valid_target_count


func _screen_position_for_node(node, fallback: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or node == null or not is_instance_valid(node):
		return fallback
	return camera.unproject_position(node.global_position)


func _fallback_party_position(index: int) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x * 0.23, viewport_size.y * (0.42 + (0.12 * index)))


func _fallback_target_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x * 0.72, viewport_size.y * 0.48)


func _await_parallel(tasks: Array[Callable]) -> void:
	var state := {"active": tasks.size()}
	if state["active"] == 0:
		return

	for task in tasks:
		var run_task := func() -> void:
			await task.call()
			state["active"] -= 1
		run_task.call()

	while state["active"] > 0:
		await get_tree().process_frame

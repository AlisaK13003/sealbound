extends Node2D

@export var prompt_on_enter: bool = true
@export var trigger_size: Vector2 = Vector2(72.0, 72.0)
@export var wake_marker_name: String = "Bedspawn"
@export var next_morning_text: String = "The next morning..."
@export var next_morning_text_duration: float = 1.5

var player_in_range: bool = false
var prompt_open: bool = false
var sleep_in_progress: bool = false
var selected_sleep: bool = false
var prompt_consumed_until_exit: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_interaction_area()

func ensure_interaction_area() -> void:
	var area: Area2D = get_node_or_null("Area2D") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "Area2D"
		add_child(area)

	area.monitoring = true
	area.monitorable = true
	area.input_pickable = true

	var collision_shape: CollisionShape2D = area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		area.add_child(collision_shape)

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = trigger_size

	var input_callback := Callable(self, "_on_area_2d_input_event")
	if not area.input_event.is_connected(input_callback):
		area.input_event.connect(input_callback)

	var body_entered_callback := Callable(self, "_on_area_2d_body_entered")
	if not area.body_entered.is_connected(body_entered_callback):
		area.body_entered.connect(body_entered_callback)

	var body_exited_callback := Callable(self, "_on_area_2d_body_exited")
	if not area.body_exited.is_connected(body_exited_callback):
		area.body_exited.connect(body_exited_callback)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("Mouse_Right_Click"):
		get_viewport().set_input_as_handled()
		show_sleep_prompt(true)

func _on_area_2d_body_entered(body: Node) -> void:
	if not body.is_in_group("Overworld_Player"):
		return
	player_in_range = true
	if prompt_on_enter:
		call_deferred("show_sleep_prompt")

func _on_area_2d_body_exited(body: Node) -> void:
	if not body.is_in_group("Overworld_Player"):
		return
	player_in_range = false
	prompt_consumed_until_exit = false

func show_sleep_prompt(force: bool = false) -> void:
	if sleep_in_progress or prompt_open:
		return
	if not player_in_range and not force:
		return
	if prompt_consumed_until_exit and not force:
		return
	if Global.is_in_menu or Global.is_paused or Fade.is_fading or AreaStateManager.currently_transitioning:
		return

	var dialogue_system: Node = get_node_or_null("/root/DialogueSystem")
	if dialogue_system == null or not dialogue_system.has_method("show_cutscene_node"):
		push_warning("Resting: DialogueSystem autoload is missing.")
		return

	selected_sleep = false
	prompt_open = true

	var choice_callback := Callable(self, "_on_sleep_choice_selected")
	if not dialogue_system.dialogue_choice_selected.is_connected(choice_callback):
		dialogue_system.dialogue_choice_selected.connect(choice_callback, CONNECT_ONE_SHOT)

	var closed_callback := Callable(self, "_on_sleep_prompt_closed")
	if not dialogue_system.dialogue_closed.is_connected(closed_callback):
		dialogue_system.dialogue_closed.connect(closed_callback, CONNECT_ONE_SHOT)

	var shown: bool = dialogue_system.show_cutscene_node({
		"speaker": "",
		"hide_portrait": true,
		"text": "Go to sleep?",
		"choices": [
			{
				"text": "Yes",
				"sleep": true
			},
			{
				"text": "No",
				"sleep": false
			}
		]
	})
	if not shown:
		prompt_open = false
		if dialogue_system.dialogue_choice_selected.is_connected(choice_callback):
			dialogue_system.dialogue_choice_selected.disconnect(choice_callback)
		if dialogue_system.dialogue_closed.is_connected(closed_callback):
			dialogue_system.dialogue_closed.disconnect(closed_callback)

func _on_sleep_choice_selected(_choice_index: int, choice_data: Dictionary) -> void:
	selected_sleep = bool(choice_data.get("sleep", false))

func _on_sleep_prompt_closed() -> void:
	var dialogue_system: Node = get_node_or_null("/root/DialogueSystem")
	var choice_callback := Callable(self, "_on_sleep_choice_selected")
	if dialogue_system != null and dialogue_system.dialogue_choice_selected.is_connected(choice_callback):
		dialogue_system.dialogue_choice_selected.disconnect(choice_callback)

	prompt_open = false
	prompt_consumed_until_exit = true
	if selected_sleep:
		call_deferred("sleep_until_next_morning")

func sleep_until_next_morning() -> void:
	if sleep_in_progress:
		return

	sleep_in_progress = true
	Global.is_in_menu = true
	Global.is_paused = true

	await Fade.fade_in(0.8)
	await show_next_morning_caption()
	StateManager.mark_slept_after_lyra_quest()
	Global.player_advanced_day(false)
	move_player_to_wake_marker()
	await get_tree().process_frame
	await Fade.fade_out(1.0)

	Global.is_paused = false
	Global.is_in_menu = false
	sleep_in_progress = false

func show_next_morning_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 350
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var label := Label.new()
	label.text = next_morning_text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(label)

	get_tree().root.add_child(layer)
	await get_tree().create_timer(next_morning_text_duration).timeout
	if is_instance_valid(layer):
		layer.queue_free()

func move_player_to_wake_marker() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("Overworld_Player") as Node2D
	var wake_marker: Node2D = find_wake_marker()
	if player == null or wake_marker == null:
		return
	player.global_position = wake_marker.global_position

func find_wake_marker() -> Node2D:
	if wake_marker_name.is_empty():
		return null

	var scene: Node = get_tree().current_scene
	if scene != null:
		var marker: Node2D = scene.find_child(wake_marker_name, true, false) as Node2D
		if marker != null:
			return marker

	var parent_node: Node = get_parent()
	if parent_node != null:
		return parent_node.find_child(wake_marker_name, true, false) as Node2D

	return null

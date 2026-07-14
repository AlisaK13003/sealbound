extends Control

@export var display_x_items: int = 5
@export var scroll_margin: int = 1
@export var mouse_scroll_detection_area: Area2D
@export var scroll_bar: VScrollBar

var can_scroll = false
var container_start_position: Vector2

var visible_range_lower = 0
var visible_range_upper = 0
var current_item = 0
var panel

var disable_selection: bool = false

func _setup():
	panel = self
	var container = get_child(0)

	if container.get_child_count() == 0:
		return 

	scroll_bar.max_value = container.get_child_count() - display_x_items
	
	visible_range_lower = 0
	visible_range_upper = display_x_items
	
	container_start_position = container.position
	
	var item_height = container.get_child(0).custom_minimum_size.y
	var separation = container.get_theme_constant("v_separation")
	var scale_y = container.scale.y
	
	panel.size.y = (display_x_items * (separation + item_height)) * scale_y
	
	current_item = 0
	if not scroll_bar.value_changed.is_connected(_on_v_scroll_bar_value_changed):
		scroll_bar.value_changed.connect(_on_v_scroll_bar_value_changed)
	update_selected_item()
	if not visibility_changed.is_connected(update_selection):
		visibility_changed.connect(update_selection)

func update_scroll_bar():
	scroll_bar.max_value = get_child(0).get_child_count() - display_x_items
	scroll_bar.value = 0

func update_selection():
	if visible:
		enable()
	else:
		disable()
		current_item = 0
	update_selected_item()
	scroll_bar.value = 0

func _ready():
	if mouse_scroll_detection_area:
		mouse_scroll_detection_area.mouse_entered.connect(_on_scroll_area_mouse_entered)
		mouse_scroll_detection_area.mouse_exited.connect(_on_scroll_area_mouse_exited)

func _on_scroll_area_mouse_entered():
	can_scroll = true

func _on_scroll_area_mouse_exited():
	can_scroll = false

func _on_v_scroll_bar_value_changed(value):
	if not panel: return
	var container = get_child(0)
	if container.get_child_count() == 0:
		return

	var item_height = container.get_child(0).custom_minimum_size.y
	var separation = container.get_theme_constant("v_separation")
	var scale_y = container.scale.y

	container.position.y = container_start_position.y - (value * (separation + item_height) * scale_y)
	
	visible_range_lower = value
	visible_range_upper = value + display_x_items
	
	var min_allowed = visible_range_lower + scroll_margin
	var max_allowed = visible_range_upper - 1 - scroll_margin
	current_item = clamp(current_item, min_allowed, max_allowed)
	
	update_selected_item()
var last_scroll_time: int = 0
@export var scroll_cooldown_ms: int = 50
func _input(event):
	if not is_visible_in_tree():
		return
	
	if disable_selection:
		return

	var current_time = Time.get_ticks_msec()
	if current_time - last_scroll_time < scroll_cooldown_ms:
		return
	
	var scrolled = false
	
	if event is InputEventMouseButton and event.is_pressed():
		if not can_scroll:
			return
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_up()
			scrolled = true
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_down()
			scrolled = true
			get_viewport().set_input_as_handled()
			
	elif Global.get_continuous_input_mapping("down"):
		scroll_down()
		scrolled = true
		get_viewport().set_input_as_handled()
	elif Global.get_continuous_input_mapping("up"):
		scroll_up()
		scrolled = true
		get_viewport().set_input_as_handled()

	if scrolled:
		last_scroll_time = current_time

func scroll_up():
	var container = get_child(0)
	var max_count = container.get_child_count()
	if max_count == 0: 
		return
	
	if current_item != 0:
		AudioManager.play_ui_sound(AudioManager.SCROLL_CLICK)
	
	current_item = clamp(current_item - 1, 0, max_count - 1)
	
	var min_allowed_index = visible_range_lower + scroll_margin
	
	if current_item < min_allowed_index:
		visible_range_lower = clamp(current_item - scroll_margin, 0, scroll_bar.max_value)
		visible_range_upper = visible_range_lower + display_x_items
		scroll_bar.value = visible_range_lower
	container.get_child(current_item).was_hovered()

	update_selected_item()

func scroll_down():
	if not panel: return
	var container = get_child(0)
	var max_count = container.get_child_count()
	if max_count == 0: 
		return
	
	if current_item != max_count - 1:
		AudioManager.play_ui_sound(AudioManager.SCROLL_CLICK)


	current_item = clamp(current_item + 1, 0, max_count - 1)
	var max_allowed_index = visible_range_upper - 1 - scroll_margin
	
	if current_item > max_allowed_index:
		visible_range_upper = current_item + 1 + scroll_margin
		visible_range_lower = clamp(visible_range_upper - display_x_items, 0, scroll_bar.max_value)
		visible_range_upper = visible_range_lower + display_x_items
		scroll_bar.value = visible_range_lower
	container.get_child(current_item).was_hovered()
	update_selected_item()

signal selection_updated
func update_selected_item():
	if not panel:
		return
	if panel.get_child_count() == 0:
		return
	for item in panel.get_child(0).get_children():
		if item.get_index() == current_item:
			item.highlight(true)
		else:
			item.highlight(false)
	selection_updated.emit(current_item)

func disable(keep_visibility: bool = false):
	self.visible = keep_visibility
	disable_selection = true
		
func enable():
	self.visible = true
	disable_selection = false

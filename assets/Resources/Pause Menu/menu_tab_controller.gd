extends GridContainer

@export var be_vertical: bool = false

@export var override_separation: bool = false

@export var only_icons: bool = false

@export var dont_offset_on_click: bool = false

@export var bypass_global_lock: bool = false
@export var disable_selection: bool = false

@export var dont_highlight: bool = false

@export var dont_disable_reselection: bool = false

var current_selection = 0
var tab_node_path = "res://assets/Resources/Pause Menu/menu_tab_node.tscn"

signal selection_changed

var starting_y: float = 0.0
var starting_x: float = 0.0

func _ready():
	if not dont_offset_on_click:
		sort_children.connect(_on_sort_children)

func _on_sort_children():
	if get_child_count() == 0:
		return
	if disable_selection:
		return

	var selected_child = get_child(current_selection)
	if not dont_highlight:
		selected_child.highlight(true)

func reset():
	current_selection = 0
	call_deferred("change_selection")
	selection_changed.emit(0)
	if not be_vertical and get_child(0).position.y == starting_y:
		get_child(0).position.y -= 10
	elif be_vertical and get_child(0).position.x == starting_x:
		get_child(0).position.x -= 10

func _setup(tab_names_, custom_tab: String = "", icons : Array[Texture2D] = []):
	#visibility_changed.connect(reset)
	current_selection = 0
	
	starting_x = 0.0
	starting_y = 0.0
	
	if be_vertical:
		self.add_theme_constant_override("separation/v", 39)
		self.columns = 1
	else:
		if custom_tab == "":
			self.columns = max(tab_names_.size(), 1)

	var largest_name: int = 0
		
	for name_ in range(tab_names_.size()):
		var new_tab
		var new_tab_instance
		
		if custom_tab == "":
			if icons.is_empty():
				new_tab = load(tab_node_path)
				new_tab_instance = new_tab.instantiate()
				new_tab_instance._setup(tab_names_[name_])
			else:
				new_tab = load(custom_tab)
				new_tab_instance = new_tab.instantiate()
				new_tab_instance._setup(icons[name_])
		else:
			if icons.is_empty():
				new_tab = load(custom_tab)
				new_tab_instance = new_tab.instantiate()
			else:
				new_tab = load(custom_tab)
				new_tab_instance = new_tab.instantiate()
				new_tab_instance._setup(icons[name_])
		self.add_child(new_tab_instance)
		new_tab_instance.gui_input.connect(cycle_input.bind(name_, true))
		if custom_tab == "" and not only_icons:
			if new_tab_instance.panel_size.x >= largest_name:
				largest_name = new_tab_instance.panel_size.x
				
	if get_child_count() == 0:
		return

	if custom_tab == "" and not only_icons:
		for child in get_children():
			child._update_size(largest_name)
			
		if not be_vertical:
			self.add_theme_constant_override("h_separation", 8)
			

#func _input(event):
#	if not Global.is_paused or not self.visible:
#		return
#	if not be_vertical:
#		if Global.get_input_mapping("left"):
#			cycle_input(null, -1)
#		if Global.get_input_mapping("right"):
#			cycle_input(null, 1)
#	else:
#		if Global.get_input_mapping("up"):
#			cycle_input(null, -1)
#		if Global.get_input_mapping("down"):
#			cycle_input(null, 1)

func cycle_input(event, index, make_noise = false):
	if get_child_count() == 0 or not visible:
		return
	if Global.cant_leave_menu and not bypass_global_lock:
		return
	if disable_selection:
		return
	if event is InputEventMouseMotion:
		return
	
	if index == current_selection and not dont_disable_reselection:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if make_noise:
				AudioManager.play_ui_sound(AudioManager.SCROLL_CLICK)

			current_selection = index
			change_selection()
	else:
		if make_noise:
			AudioManager.play_ui_sound(AudioManager.SCROLL_CLICK)
		current_selection = clamp(current_selection + index, 0, self.columns - 1 if not be_vertical else get_child_count() - 1)
		change_selection()

func change_selection():
	if get_child_count() == 0:
		return

	current_selection = clamp(current_selection, 0, get_child_count() - 1)
	for child in get_child_count():
		if child == current_selection:
			if not only_icons and not dont_highlight:
				get_child(child).highlight(true)
		else:
			if not only_icons and not dont_highlight:
				get_child(child).highlight(false)

	selection_changed.emit(current_selection)

func set_active(active):
	disable_selection = not active

func disabled():
	disable_selection = true

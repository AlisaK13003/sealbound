extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs

@onready var skill_card_container = $Control

var active_skill_instance_id: int = -1

var _is_snapping_back: bool = false

var caster_index: int = 0
var trying_to_use_skill: bool = false
var skill_used: moves

func _ready():
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child, true)
		var new_skill_card = load("res://assets/Resources/Pause Menu/Skills Menu/party_skill_card.tscn")
		var card_instance = new_skill_card.instantiate()
		card_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		skill_card_container.add_child(card_instance)
		if card_instance.get_index() != 0:
			card_instance.visible = false
			
	menu_tabs.selection_changed.connect(_tab_changed)
	
	for card in $Control.get_children():
		for move_card in card.move_container.get_children():
			move_card.skill_clicked.connect(update_skill_description)
			
	visibility_changed.connect(_on_visibility_changed)
	
	_on_visibility_changed()
	GlobalCombatInformation.update_resonance.connect(_setup)
	GlobalCombatInformation.member_added.connect(_setup)
	
func _setup():
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
	for child in skill_card_container.get_children():
		skill_card_container.remove_child(child)
		child.queue_free()
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child, true)
		var new_skill_card = load("res://assets/Resources/Pause Menu/Skills Menu/party_skill_card.tscn")
		var card_instance = new_skill_card.instantiate()
		card_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		skill_card_container.add_child(card_instance)
		if card_instance.get_index() != 0:
			card_instance.visible = false
				
	for card in $Control.get_children():
		for move_card in card.move_container.get_children():
			move_card.skill_clicked.connect(update_skill_description)
				
	_on_visibility_changed()
	
func _on_visibility_changed() -> void:
	if visible:
		active_skill_instance_id = -1
		for child in menu_tabs.get_children():
			_set_node_mouse_disabled(child, false)
			
		if menu_tabs.has_method("cycle_input"):
			menu_tabs.cycle_input(null, -1000) 
			menu_tabs.cycle_input(null, 0)     
		
		_tab_changed(0)
	else:
		for child in menu_tabs.get_children():
			_set_node_mouse_disabled(child, false)
			
		if menu_tabs.has_method("cycle_input"):
			menu_tabs.cycle_input(null, -1000)

func _tab_changed(tab):
	menu_tabs.current_selection = tab
	for child in skill_card_container.get_children():
		if child.get_index() == tab:
			child.visible = true
			$Skill_Description/AnimatedSprite2D.sprite_frames = GlobalCombatInformation.all_party_slots[child.get_index()].sprite_frames
			_trigger_default_skill_selection(child)
		else:
			child.visible = false

func _trigger_default_skill_selection(card_node: Node) -> void:
	if card_node.get_child_count() > 0:
		var moves_node = card_node.get_child(0) 
		if moves_node.get_child_count() > 0:
			var first_move = moves_node.get_child(0)
			update_skill_description(first_move.get_instance_id())

func update_skill_description(pressed_skill):
	active_skill_instance_id = pressed_skill
	
	var selected_skill: moves
	var move_index: int
	for move in skill_card_container.get_child(menu_tabs.current_selection).get_child(0).get_children():
		if move.get_instance_id() == pressed_skill:
			selected_skill = move.stored_move
			move_index = move.get_index()
			if move.has_method("update_selection"):
				move.update_selection(true)
		else:
			if move.has_method("update_selection"):
				move.update_selection(false)
				
	if selected_skill == null:
		return
	$Skill_Description/TextureRect.texture = selected_skill.move_sprite if selected_skill.move_sprite != null else null
	$Skill_Description/Label.text = selected_skill.move_description
	$Skill_Description/Label2.text = selected_skill.move_name
	$Skill_Description/Label3.text = str(selected_skill.mana_cost) + " BP"
	if $Skill_Description/AnimatedSprite2D.sprite_frames.has_animation("On_Attack_" + str(move_index + 1)):
		$Skill_Description/AnimatedSprite2D.play("On_Attack_" + str(move_index + 1))

func _ready_to_use_skill(skill_to_use: moves):
	if not skill_to_use.does_heal_party:
		return
	skill_used = skill_to_use
	
	caster_index = menu_tabs.current_selection
	trying_to_use_skill = true
	
	if skill_to_use.aoe_heal:
		for child in menu_tabs.get_children():
			child.highlight(true)
			_set_node_mouse_disabled(child, false)
	elif skill_to_use.targets_self:
		for child in menu_tabs.get_children():
			if child.get_index() == caster_index:
				child.highlight(true)
				_set_node_mouse_disabled(child, false)
			else:
				child.highlight(false)
				_set_node_mouse_disabled(child, true) 
	else:
		for child in menu_tabs.get_children():
			child.highlight(child.get_index() == caster_index)
			_set_node_mouse_disabled(child, false)

func _set_node_mouse_disabled(node: Node, disabled: bool) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_PASS
	if node is BaseButton:
		node.disabled = disabled
	for child in node.get_children():
		_set_node_mouse_disabled(child, disabled)

func _input(event: InputEvent) -> void:
	if trying_to_use_skill:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()

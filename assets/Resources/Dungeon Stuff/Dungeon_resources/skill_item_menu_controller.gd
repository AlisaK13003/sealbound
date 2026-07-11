extends Control

@export var is_item_menu: bool = false
@export var is_for_options: bool = false


var list_node = "res://assets/Resources/Pause Menu/skill_item_node.tscn"

var container

var selected_item
var selected_item_index

func _setup(move_list: Array[moves] = []):	
	container = $Panel/GridContainer
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	if not is_for_options:
		if is_item_menu:
			for item in GlobalCombatInformation.all_held_items:
				var new_item = load(list_node)
				var new_item_instance = new_item.instantiate()
				new_item_instance._setup(item)
				new_item_instance.did_a_thing.connect(node_selected)
				new_item_instance.just_hovered.connect(node_hovered)
				container.add_child(new_item_instance)
			$Background/Label.text = "Items"
		else:
			$Background/Label.text = "Skills"
			for move in move_list:
				var new_skill = load(list_node)
				var new_skill_instance = new_skill.instantiate()
				new_skill_instance._setup(move)
				new_skill_instance.did_a_thing.connect(node_selected)
				new_skill_instance.just_hovered.connect(node_hovered)
				container.add_child(new_skill_instance)
	else:
		var defend_option = load(list_node)
		var defend_instance = defend_option.instantiate()
		defend_instance._setup("Defend")
		defend_instance.did_a_thing.connect(node_selected)
		defend_instance.just_hovered.connect(node_hovered)
		container.add_child(defend_instance)
		
		var run_option = load(list_node)
		var run_instance = run_option.instantiate()
		run_instance._setup("Run")
		run_instance.did_a_thing.connect(node_selected)
		run_instance.just_hovered.connect(node_hovered)
		container.add_child(run_instance)
		
		var action_queue_option = load(list_node)
		var action_queue_instance = action_queue_option.instantiate()
		action_queue_instance._setup("Action Queue")
		action_queue_instance.did_a_thing.connect(node_selected)
		action_queue_instance.just_hovered.connect(node_hovered)
		container.add_child(action_queue_instance)
	$Panel._setup()

func node_hovered(at_what_index):
	$Panel.current_item = at_what_index
	$Panel.update_selected_item()

signal thing_selected
func node_selected(what_thing = null, index = 0):
	if what_thing == null:
		what_thing = container.get_child($Panel.current_item).stored_thing
		index = $Panel.current_item
	
	selected_item = what_thing
	selected_item_index = index
	self.visible = false
	if not is_for_options:
		thing_selected.emit(what_thing)
	else:
		thing_selected.emit(selected_item_index)

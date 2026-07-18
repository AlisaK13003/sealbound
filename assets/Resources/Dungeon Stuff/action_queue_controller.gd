extends Control

@onready var turn_queue_container = $GridContainer
const PORTRAIT_SCENE = "res://assets/Resources/Dungeon Stuff/Action_Queue_Node.tscn"

func update_turn_queue_ui(upcoming_turns):
	for child in turn_queue_container.get_children():
		child.queue_free()
	
	var new_portrait = load(PORTRAIT_SCENE)
	for entity in range(upcoming_turns.size()):
		if upcoming_turns[entity].is_dead:
			continue
		var portrait = new_portrait.instantiate()
		turn_queue_container.add_child(portrait)

		portrait.setup(upcoming_turns[entity], entity)

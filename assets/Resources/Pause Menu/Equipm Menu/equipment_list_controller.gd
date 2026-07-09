extends GridContainer

@export_enum("Weapon", "Helmet", "Chestplate", "Boot", "Charm") var what_equipment_am_i = 0

var equipment_node = "res://assets/Resources/Pause Menu/Equipm Menu/Equipment_List_Node.tscn"

signal equipment_swapped

func _setup():
	var stored_equipment_list = []
	if what_equipment_am_i == 0:
		for weapon_ in GlobalCombatInformation.all_held_weapons:
			stored_equipment_list.append(weapon_)
	else:
		for equipment_: equipment in GlobalCombatInformation.all_held_equipment:
			if equipment_.equipment_type == what_equipment_am_i - 1:
				stored_equipment_list.append(equipment_)
				
	for equipment_ in stored_equipment_list:
		var new_node = load(equipment_node)
		var new_node_instance: Control = new_node.instantiate()
		
		new_node_instance._setup(equipment_, true if what_equipment_am_i == 0 else false)
		
		new_node_instance.node_pressed.connect(equipment_selected)
		
		add_child(new_node_instance)
		#new_node_instance.move_left(new_node_instance.get_index())
	sort_children()
	GlobalCombatInformation.equipment_added.connect(_reset_contents)
		
func equipment_selected(instance_id, equip):
	#for child in get_children():
	#	if child.get_instance_id() == instance_id:
	#		remove_child(child)
	#		break
	for child in get_children():
		if child.get_index() != instance_id:
			child.highlight(false)
		elif child.get_index() == instance_id:
			get_parent().current_item = child.get_index()
			get_parent().update_selected_item()
	
	equipment_swapped.emit(equip)

func _reset_contents():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var stored_equipment_list = []

	if what_equipment_am_i == 0:
		for weapon_ in GlobalCombatInformation.all_held_weapons:
			stored_equipment_list.append(weapon_)
	else:
		for equipment_: equipment in GlobalCombatInformation.all_held_equipment:
			if equipment_.equipment_type == what_equipment_am_i - 1:
				stored_equipment_list.append(equipment_)
				
	for equipment_ in stored_equipment_list:
		var new_node = load(equipment_node)
		var new_node_instance: Control = new_node.instantiate()
		
		new_node_instance._setup(equipment_, true if what_equipment_am_i == 0 else false)
		
		new_node_instance.node_pressed.connect(equipment_selected)
		
		add_child(new_node_instance)
	sort_children()

func update_contents(new_equipment):
	if new_equipment == null:
		return
	var new_node = load(equipment_node)
	var new_node_instance = new_node.instantiate()
	
	new_node_instance._setup(new_equipment, true if what_equipment_am_i == 0 else false)
	
	new_node_instance.node_pressed.connect(equipment_selected)
	
	#add_child(new_node_instance)
	#new_node_instance.move_left(new_node_instance.get_index())
	sort_children()

func sort_children():
	var sorted_children = get_children()
	
	sorted_children.sort_custom(func(a, b):
		return a.equip_name.text.naturalnocasecmp_to(b.equip_name.text) < 0
	)
	
	for i in range(sorted_children.size()):
		move_child(sorted_children[i], i)

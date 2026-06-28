extends Control

@onready var quest_menu = $Quest_Menu
@onready var chest_drop_parent = $VBoxContainer

var chest_got_node_path = "res://scenes/Dungeon/Explorable_Dungeon_Test/chest/Chest_Reward_Display_Node.tscn"

func _ready():
	quest_menu.activated.connect(_open_quest_menu)
	
func _open_quest_menu():
	print("QUEST MENU")

func display_gotten_chest_items(item_got):
	for item in item_got:
		var new_node = load(chest_got_node_path)
		var new_node_instance = new_node.instantiate()
		new_node_instance._setup(item, 0)
		chest_drop_parent.add_child(new_node_instance)
		if not is_inside_tree():
			break
		await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	await get_tree().create_timer(1.0).timeout
	for child in chest_drop_parent.get_children():
		child.queue_free()
		if not is_inside_tree():
			break
		await get_tree().create_timer(1.5).timeout
	

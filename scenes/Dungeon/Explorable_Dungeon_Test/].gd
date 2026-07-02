extends Control

@onready var quest_menu_button = $Quest_Menu
@onready var chest_drop_parent = $VBoxContainer
@onready var quest_menu = $QuestMenu

var chest_got_node_path = "res://scenes/Dungeon/Explorable_Dungeon_Test/chest/Chest_Reward_Display_Node.tscn"
var p_ref

func _ready():
	quest_menu_button.activated.connect(_open_quest_menu)
	quest_menu.visible = false
	quest_menu._setup(p_ref)
	
func _setup(parent_ref):
	p_ref = parent_ref
	
	
func _open_quest_menu():
	if quest_menu.visible:
		quest_menu.visible = false
		p_ref.movement_locked = false
	else:
		quest_menu.visible = true
		p_ref.movement_locked = true

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
	
func _on_check_box_toggled(toggled_on):
	for enemy in p_ref.enemy_container.get_children():
		if toggled_on:
			enemy.disable_player_detection()
		else:
			enemy.enable_player_detection()

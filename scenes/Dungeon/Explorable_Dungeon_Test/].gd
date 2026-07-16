extends Control

@onready var chest_drop_parent = $VBoxContainer
@onready var mini_map = $MiniMap
@onready var pause_menu = $PauseMenu

var chest_got_node_path = "res://scenes/Dungeon/Explorable_Dungeon_Test/chest/Chest_Reward_Display_Node.tscn"
var p_ref
 
func _ready():
	$HBoxContainer3/HBoxContainer2.visible = false
	$HBoxContainer3/HBoxContainer.visible = false
	GlobalCombatInformation.obtained_or_used_key.connect(update_key_values)
	
func update_key_values():
	if GlobalCombatInformation.holding_boss_key > 0:
		$HBoxContainer3/HBoxContainer.visible = true
		$HBoxContainer3/HBoxContainer/Label.text = "x" + str(GlobalCombatInformation.holding_boss_key_key)
	else:
		$HBoxContainer3/HBoxContainer.visible = false
		
	if GlobalCombatInformation.holding_basic_room_key > 0:
		$HBoxContainer3/HBoxContainer2.visible = true
		$HBoxContainer3/HBoxContainer2/Label.text = "x" + str(GlobalCombatInformation.holding_basic_room_key)
	else:
		$HBoxContainer3/HBoxContainer2.visible = false

func _setup(parent_ref):
	p_ref = parent_ref
	
func _setup_dungeon_pause():
	pause_menu._setup(p_ref, p_ref.generated_rooms)

func clear_maps():
	if mini_map != null:
		mini_map.clear_mini_map()
	if pause_menu != null and pause_menu.mini_map != null:
		pause_menu.mini_map.clear_mini_map()

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

func _input(event):
	if Global.get_input_mapping("Pause"):
		if not pause_menu.visible:
			if Global.is_in_menu:
				return
			mini_map.hide_mini_map()
			Global.menu_opened.emit()
			Global.is_paused = true
			pause_menu.visible = true
			pause_menu.update_fsm()
			get_tree().paused = true
			get_viewport().set_input_as_handled()
		else:
			Global.menu_closed.emit()
			mini_map.open_mini_map()
			Global.is_paused = false
			get_tree().paused = false
			pause_menu.visible = false

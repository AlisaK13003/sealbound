extends Control

@onready var party_container = $CanvasLayer/VBoxContainer2
@onready var actual_rewards_screen_container = $CanvasLayer/Container

@onready var next_button = $CanvasLayer/GenericButton
@onready var return_button = $CanvasLayer/GenericButton2

@onready var total_gold = $CanvasLayer/Container/MarginContainer/VBoxContainer/HBoxContainer/total_gold
@onready var gold_gained = $CanvasLayer/Container/MarginContainer/VBoxContainer/HBoxContainer/coins_gained
@onready var items_gained = $CanvasLayer/Container/MarginContainer/VBoxContainer/GridContainer

var tot_gold = 0
var gold_obtained = 0
var obtained_items: Array[Items] = []

func _ready():
	next_button.pressed.connect(swapped_page)
	return_button.pressed.connect(_leave_rewards_screen)
	
func _leave_rewards_screen():
	Global.current_loading_zone = "Infirmary_Spawn"
	await Fade.fade_in()		
	Fade.change_scene(Global.location_paths["Village"])

func _setup(coins_gained: int , experience_gained: int, bond_gained: int, items_gained: Array[Items]):
	gold_obtained = coins_gained
	tot_gold = GlobalCombatInformation.currency_held
	obtained_items = items_gained
	
	for active_member in GlobalCombatInformation.active_party_slots:
		var index = GlobalCombatInformation.active_party_slots.find(active_member)
		var child_to_update = party_container.get_child(index)
		child_to_update.get_node("TextureRect").texture = active_member.party_member_portrait
		child_to_update.get_node("VBoxContainer/HBoxContainer").get_node("Name").text = active_member.combatant_name
		child_to_update.get_node("VBoxContainer/HBoxContainer").get_node("Total_EXP").text = str(active_member.total_experience_points)
		child_to_update.get_node("VBoxContainer/HBoxContainer2").get_node("Current_Level").text = str(active_member.combatant_stats.level)
		child_to_update.get_node("VBoxContainer/HBoxContainer2").get_node("Points_to_next_level").text = str(active_member.add_experience(0))

func swapped_page():
	party_container.visible = false
	actual_rewards_screen_container.visible = true
	next_button.visible = false
	return_button.visible = true
	total_gold.text = "Gold:\t" + str(tot_gold)
	gold_gained.text = "Gained Gold:\t" + str(gold_obtained)
	print(obtained_items.size())
	for item: Items in obtained_items:
		var new_item = Label.new()
		new_item.custom_minimum_size.x = 70
		new_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		new_item.text = item.item_name
		items_gained.add_child(new_item)
	if items_gained.get_child_count() == 0:
		var new_item = Label.new()
		new_item.text = "No items"
		new_item.custom_minimum_size.x = 70
		new_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		items_gained.add_child(new_item)		
		

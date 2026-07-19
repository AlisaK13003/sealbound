extends Control

@onready var party_container = $CanvasLayer/VBoxContainer2
@onready var actual_rewards_screen_container = $CanvasLayer/Container

@onready var next_button = $CanvasLayer/Next_Button
@onready var return_button = $CanvasLayer/Return_Button

@onready var total_gold = $CanvasLayer/Container/MarginContainer/VBoxContainer/HBoxContainer/total_gold
@onready var gold_gained = $CanvasLayer/Container/MarginContainer/VBoxContainer/HBoxContainer/coins_gained
@onready var items_gained = $CanvasLayer/Container/MarginContainer/VBoxContainer/MarginContainer/GridContainer

@onready var background = $TextureRect

@onready var label_template = $Label

var tot_gold = 0
var gold_obtained = 0
var obtained_items

signal portraits_populated

func _ready():
	next_button.activated.connect(swapped_page)
	return_button.activated.connect(_leave_rewards_screen)
	
	await portraits_populated
	await Fade.fade_out(0.5)
	party_container.add_theme_constant_override("separation", 400)
	var tween = create_tween()
	tween.tween_property(party_container, "theme_override_constants/separation", 100, 1)
	
	await tween.finished

var in_cycle = false
func _physics_process(delta):
	if not in_cycle:
		in_cycle = true
		background.rotation_degrees = -360
		var tween = create_tween()
		tween.tween_property(background, "rotation", 360, 360)
		await tween.finished
		in_cycle = false

func _leave_rewards_screen():
	return_button.visible = false
	if not next_button.visible:
		Global.current_location = "Village"
		Global.current_loading_zone = "Infirmary_Spawn"
		await Fade.fade_in(1)		
		GlobalCombatInformation.bring_back_combat(self)

func _setup(coins_gained: int , experience_gained: int, bond_gained: int, items_gained = null):
	gold_obtained = coins_gained
	tot_gold = GlobalCombatInformation.currency_held
	obtained_items = items_gained
	
	for active_member in GlobalCombatInformation.active_party_slots:
		var index = GlobalCombatInformation.active_party_slots.find(active_member)
		var child_to_update = party_container.get_child(index)
		child_to_update._setup(active_member)
	for child in party_container.get_children():
		if child.get_index() >= GlobalCombatInformation.active_party_slots.size():
			child.queue_free()
	portraits_populated.emit()

func swapped_page():
	if next_button.visible:
		party_container.visible = false
		actual_rewards_screen_container.visible = true
		$NinePatchRect.visible = true
		next_button.visible = false
		return_button.visible = true
		total_gold.text = "Gold: \t" + str(tot_gold)
		gold_gained.text = "Gained Gold: \t" + str(gold_obtained)
		if obtained_items != null:
			for item: String in obtained_items:
				var new_item = Label.new()
				new_item.label_settings = label_template.label_settings
				new_item.custom_minimum_size.x = 100
				new_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				var actual_item = load(item)
				
				new_item.text = actual_item.item_name
				if items_gained != null :
					items_gained.add_child(new_item)
		if items_gained.get_child_count() == 0:
			var new_item = Label.new()
			new_item.label_settings = label_template.label_settings
			new_item.text = "No items"
			new_item.custom_minimum_size.x = 70
			new_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			items_gained.add_child(new_item)		
		

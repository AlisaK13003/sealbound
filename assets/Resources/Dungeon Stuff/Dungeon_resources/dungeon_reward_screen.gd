extends Control

@onready var return_button = $Return_Button

@onready var background = $TextureRect

@onready var experience_gained_label = $Control/Contents/Label4
@onready var item_label = $Control/Contents/Label3

var tot_gold = 0
var gold_obtained = 0
var obtained_items

signal portraits_populated

func _ready():
	return_button.activated.connect(_leave_rewards_screen)
	
	await Fade.fade_out(0.5)

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
	Global.current_location = "Village"
	Global.current_loading_zone = "Infirmary_Spawn"
	await Fade.fade_in(1)		
	GlobalCombatInformation.bring_back_combat(self)

func _setup(who_leveled_up, experience_gained: int, items_gained = null):
	obtained_items = items_gained
	
	var sorted_item_gained = []

	if obtained_items == null:
		pass
	else:
		for item in obtained_items:
			if item == null or item == "":
				continue
			var mew_item = load(item)
			var temp_copy = mew_item.duplicate()

			if temp_copy.stack != 1: temp_copy.stack = 1
			var index = sorted_item_gained.find_custom(func(new_item: Items): return new_item.item_name == temp_copy.item_name)
			if index != -1:
				sorted_item_gained[index].stack += temp_copy.stack
			else:
				sorted_item_gained.append(temp_copy)
		if not sorted_item_gained.is_empty():
			var path = "res://assets/Resources/Dungeon Stuff/List_Item.tscn"
			for thing in sorted_item_gained:
				var new_item_inst = load(path)
				var new_item_instance = new_item_inst.instantiate()
				$Control/Contents/GridContainer.add_child(new_item_instance)
				new_item_instance._setup(thing, thing.stack, null, true)
			
	
	experience_gained_label.text = "EXP Gained: " + str(experience_gained)
	
	for child in $Control/Contents/HBoxContainer.get_children():
		if child.get_index() >= GlobalCombatInformation.all_party_slots.size():
			child.queue_free()
		else:
			var level_up = "YAY" if who_leveled_up[child.get_index()] else "BOO"
			child.get_node("Sprite2D").texture = GlobalCombatInformation.all_party_slots[child.get_index()].party_member_portrait
			child.get_node("Label").text = "Lv: " + str(GlobalCombatInformation.all_party_slots[child.get_index()].combatant_stats.level) + " " + level_up
	
	portraits_populated.emit()

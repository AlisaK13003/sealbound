extends Control

@onready var menu = $GenericMenu
@onready var tabs = $GenericMenu.get_children()

func _ready():
	for child in $GenericMenu/Menu_Tabs.get_children():
		if child.get_index() >= GlobalCombatInformation.all_party_slots.size():
			child.visible = false
			continue
			
	for child in tabs:
		if child.get_index() < menu.child_offset or child.get_index() > GlobalCombatInformation.all_party_slots.size() +1:
			continue
		else:
			child.setup(GlobalCombatInformation.all_party_slots[child.get_index() - menu.child_offset])

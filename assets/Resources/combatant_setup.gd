extends Control

@onready var combatant_name = $Label
@onready var combatant_sprite = $Sprite2D
@onready var health_bar = $TextureProgressBar
@onready var interactable_area = $Area2D

var stored_combatant : generic_combatants


func setup(combatant : generic_combatants):
	stored_combatant = combatant
	combatant_name.text = combatant.combatant_name
	combatant_sprite.texture = combatant.combatant_sprite
	health_bar.max_value = combatant.combatant_stats.max_health
	health_bar.value = combatant.combatant_stats.health
	if combatant.is_combatant_enemy:
		combatant_sprite.flip_h = false
	combatant.combatant_stats.health_changed.connect(update_health)
	interactable_area.input_event.connect(do_nothing)
	
func do_nothing(viewport, event, shape_idx):
	if event is InputEventMouseButton and stored_combatant.is_combatant_enemy:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("HIII")
	
func update_health(change_health_value):
	health_bar.value = change_health_value
	if health_bar.value == 0:
		on_death()

func do_basic_attack():
	return (stored_combatant.combatant_stats.attack)

func on_death():
	self.visible = false

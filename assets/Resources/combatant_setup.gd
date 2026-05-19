extends Control

@onready var combatant_name = $Label
@onready var combatant_sprite = $TextureRect
@onready var health_bar = $TextureProgressBar

func setup(combatant : generic_combatant):
	combatant_name.text = combatant.combatant_name
	combatant_sprite.texture = combatant.combatant_sprite
	health_bar.max_value = combatant.combatant_stats.max_health
	health_bar.value = combatant.combatant_stats.health
	if combatant.is_combatant_enemy:
		combatant_sprite.flip_h = false
	combatant.combatant_stats.health_changed.connect(update_health)
	
func update_health(change_health_value):
	health_bar.value = change_health_value
	if health_bar.value == 0:
		on_death()
		
func on_death():
	self.visible = false

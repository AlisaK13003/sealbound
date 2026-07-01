extends Control

var panel: Panel

func _setup(combatant: generic_combatants):
	var name_ = $Label
	var sprite = $Sprite2D
	
	panel = $Panel
	
	name_.text = combatant.combatant_name
	sprite.texture = combatant.party_member_portrait
	
func update_highlight(highlight):
	var stylebox = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	if highlight:
		stylebox.bg_color = Color.AQUA
	else:
		stylebox.bg_color = Color.GRAY

	panel.add_theme_stylebox_override("panel", stylebox)

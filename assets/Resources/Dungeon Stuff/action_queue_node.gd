extends Control

func setup(combatant, index):
	if combatant == null:
		self.queue_free()
		return
	$HBoxContainer/Label.text = combatant.stored_combatant.combatant_name
	if index == 0:
		$Label2.text = "Acting"
	elif index == 1:
		$Label2.text = "next"
	else:
		$Label2.text = str(index + 1)
	if combatant.stored_combatant.is_combatant_enemy:
		$HBoxContainer/Container/Sprite2D.texture = null
	else:
		$HBoxContainer/Container/Sprite2D.texture = combatant.stored_combatant.party_member_portrait

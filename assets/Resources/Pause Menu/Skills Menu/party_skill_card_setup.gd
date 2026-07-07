extends Control

var skill_path = "res://assets/Resources/Pause Menu/Skills Menu/Skill_Node.tscn"

var move_container

func _setup(combatant: generic_combatants):
	move_container = $GridContainer
	for skill in range(combatant.combatant_skills.size()):
		var new_skill = load(skill_path)
		var skill_instance = new_skill.instantiate()
		
		skill_instance._setup(combatant.combatant_skills[skill])
		move_container.add_child(skill_instance)
		
		if skill == 0:
			skill_instance.update_selection(true)

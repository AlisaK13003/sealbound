extends Control

var skill_path = "res://assets/Resources/Pause Menu/Skills Menu/Skill_Node.tscn"

var move_container

func _setup(combatant: generic_combatants):
	move_container = $GridContainer
	var count = 0
	for skill in combatant.combatant_skills_.keys():
		if combatant.combatant_skills_[skill]:
			var new_skill = load(skill_path)
			var skill_instance = new_skill.instantiate()
			
			skill_instance._setup(skill)
			move_container.add_child(skill_instance)
			
			if count == 0:
				skill_instance.update_selection(true)
			count += 1

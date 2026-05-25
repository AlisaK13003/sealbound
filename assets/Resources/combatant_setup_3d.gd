extends Node3D

class_name combat_template

@onready var combatant_name = $Sprite3D2/SubViewport/CombatantUi.get_node("Label")
@onready var combatant_sprite = $Sprite3D
@onready var health_bar = $Sprite3D2/SubViewport/CombatantUi.get_node("TextureProgressBar")
@onready var interactable_area = $Area3D
@onready var attacked_label = $Label3D
@onready var combatant_ui_ = $Sprite3D2/SubViewport/CombatantUi
@onready var combatant_ui = $Sprite3D2/SubViewport/CombatantUi/Player_Menu
@onready var combatant_ui_area = $Sprite3D2/Area3D

@onready var subviewport = $Sprite3D2/SubViewport
@onready var rng = RandomNumberGenerator.new()

var currently_selectable : bool
var stored_combatant : generic_combatants
var parent_reference
var child_number: int
var is_empty : bool
var is_defending : bool = false
var all_active_effects = 0
var active_statuses : Array[status]

# Percentages that stat buff / debuffs affect combat
var attack_up_down: float = 1.25
var defense_up_down: float = 1.25
var evasion_up_down: float = 1.25
var accuracy_up_down: float = 1.25
var critchance_up_down: float = 1.25
var speed_up_down: float = 1.25

enum statuses {
	STUN = 1 << 0,
	SLEEP = 1 << 1,
	SHOCK = 1 << 2,
	POISON = 1 << 3,
	BURN = 1 << 4,
	FREEZE = 1 << 5,
	SLOW = 1 << 6,
	AGRO = 1 << 7,
	ATTACKdown = 1 << 8,
	DEFENSEdown = 1 << 9,
	EVASIONdown = 1 << 10,
	CRITCHANCEdown = 1 << 11,
	ACCURACYdown = 1 << 12,
	MOMENTUM = 1 << 13,
	REGEN = 1 << 14,
	STUNIMMUNITY = 1 << 15,
	ATTACKup = 1 << 16,
	DEFENSEup = 1 << 17,
	EVASIONup = 1 << 18,
	CRITCHANCEup = 1 << 19,
	ACCURACYup = 1 << 20,
}

var conflicts = {
	statuses.ATTACKdown: statuses.ATTACKup,
	statuses.ATTACKup: statuses.ATTACKdown,
	statuses.DEFENSEdown: statuses.DEFENSEup,
	statuses.DEFENSEup: statuses.DEFENSEdown,
	statuses.EVASIONdown: statuses.EVASIONup,
	statuses.ACCURACYdown: statuses.ACCURACYup,
	statuses.EVASIONup: statuses.EVASIONdown,
	statuses.CRITCHANCEdown: statuses.CRITCHANCEup,
	statuses.CRITCHANCEup: statuses.CRITCHANCEdown,
	statuses.ACCURACYup: statuses.ACCURACYdown
}

@onready var status_map: Dictionary = {
	statuses.STUN: _apply_stun,
	statuses.SLEEP: _apply_sleep,
	statuses.SHOCK: _apply_shock,
	statuses.POISON: _apply_poison,
	statuses.BURN: _apply_burn,
	statuses.FREEZE: _apply_freeze,
	statuses.SLOW: stat_does_nothing,
	statuses.AGRO: _apply_agro,
	statuses.ATTACKdown: stat_does_nothing,
	statuses.DEFENSEdown: stat_does_nothing,
	statuses.EVASIONdown: stat_does_nothing,
	statuses.CRITCHANCEdown: stat_does_nothing,
	statuses.ACCURACYdown: stat_does_nothing,
	statuses.MOMENTUM: _apply_momentum,
	statuses.REGEN: _apply_regen,
	statuses.STUNIMMUNITY: _apply_stun_imm,
	statuses.ATTACKup: stat_does_nothing,
	statuses.DEFENSEup: stat_does_nothing,
	statuses.EVASIONup: stat_does_nothing,
	statuses.CRITCHANCEup: stat_does_nothing,
	statuses.ACCURACYup: stat_does_nothing
}

enum stats {ATTACK, DEFENSE, ACCURACY, EVASION, CRIT_CHANCE, SPEED, MAGIC}

func setup(combatant : generic_combatants, parent_ref, child_num):
	if combatant == null:
		is_empty = true
		return
		
	all_active_effects = 0
	active_statuses.clear()
	is_defending = false
		
	child_number = child_num
	parent_reference = parent_ref
	stored_combatant = combatant
	combatant_name.text = combatant.combatant_name
	combatant_sprite.texture = combatant.combatant_sprite
	health_bar.max_value = combatant.combatant_stats.max_health
	health_bar.value = combatant.combatant_stats.health
	if combatant.is_combatant_enemy:
		combatant_sprite.flip_h = false
	else:
		$Sprite3D2/SubViewport/CombatantUi/TextureProgressBar.visible = false
	combatant_ui.visible = false
	combatant_ui_area.visible = false
	create_collision_from_sprite_3d()
	$Sprite3D2/SubViewport/CombatantUi.setup(self, stored_combatant)
	
func update_health(change_health_value, status_ = false, portrait: player_portraits = null):
	if not status_:
		if str(change_health_value) == "MISS":
			await update_damage_label(0, false, true)
		else:
			if is_defending:
				portrait._update_health(change_health_value)
				await update_damage_label(change_health_value * 0.4, false, false)
			else:
				if portrait == null:
					health_bar.value -= floor(change_health_value[0])
				else:
					portrait._update_health(change_health_value[0])
				await update_damage_label(change_health_value, false, false)
			if is_defending:
				stored_combatant.combatant_stats.health -= floor(change_health_value[0] * 0.4)
			else:
				stored_combatant.combatant_stats.health -= change_health_value[0]
	else:
		if not stored_combatant.is_combatant_enemy:
			parent_reference.get_player_portrait(child_number)._update_health(change_health_value)
		else:
			health_bar.value -= floor(change_health_value)
			attacked_label.text = str(int(floor(change_health_value)))
			
	await get_tree().create_timer(0.5).timeout
	
	attacked_label.text = ""
	if stored_combatant.combatant_stats.health <= 0:
		on_death()
	parent_reference.turn_ended.emit()

func update_damage_label(damage_taken, _was_heal = false, attack_missed = false):
	if attack_missed:
		attacked_label.modulate = Color.MAGENTA
		attacked_label.text = "MISS"
	elif not damage_taken[1] is String and damage_taken[1] == 1:
		attacked_label.modulate = Color.RED
		attacked_label.text = "CRIT"
		await get_tree().create_timer(0.5).timeout
		attacked_label.text = str(int(floor(damage_taken[0])))
	elif damage_taken[1] is String and not damage_taken[1] == "":
		attacked_label.modulate = Color.LAWN_GREEN
		attacked_label.text = str(int(floor(-1 * damage_taken[0])))
	else:
		attacked_label.modulate = Color.INDIAN_RED
		attacked_label.text = str(int(floor(damage_taken[0])))
	await get_tree().create_timer(0.5).timeout
	attacked_label.text = ""

# Combat related stuff
func calculate_evasion(entity_being_attacked: combat_template, attack_hit_chance = 90):
	if not stored_combatant.is_combatant_enemy:
		return ((obtain_stat(stats.EVASION) + 200) / (entity_being_attacked.obtain_stat(stats.EVASION) + 200)) * (attack_hit_chance * obtain_stat_alteration(stats.ACCURACY))
	else:
		return (((obtain_stat(stats.EVASION) + 200) / (entity_being_attacked.obtain_stat(stats.EVASION) + 200)) * (attack_hit_chance * obtain_stat_alteration(stats.ACCURACY))) * ((obtain_stat(stats.EVASION) + 200) / ((((stored_combatant.stored_equipment.equipment_stats.evasion * obtain_stat_alteration(stats.EVASION))) / 2) + 200))

func execute_base_attack(entity_node: combat_template):
	var chance_to_hit = calculate_evasion(entity_node)
	var chance = rng.randf_range(0, 1)

	if (chance * 100) <= chance_to_hit:
		return 5 * sqrt((obtain_stat(stats.ATTACK) / (entity_node.obtain_stat(stats.DEFENSE) + 1)) * (stored_combatant.stored_weapon.weapon_attack * obtain_stat_alteration(stats.ACCURACY))) * randf_range(0.95, 1.05)
	else:
		return "MISS"

func on_death():
	self.visible = false
	stored_combatant.is_dead = true

func execute_defend():
	is_defending = true

# Checks if you can click the entity to execute skill/attack
func do_nothing_3d(_camera, event, _event_position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)

func reset_ui():
	combatant_ui.get_parent().reset_ui()

# Status Stuff
func handle_status(incoming_statuses):
	for key in conflicts.keys():
		var opposite = conflicts[key]
		if (incoming_statuses & key) and (all_active_effects & opposite):
			_remove_active_status(opposite)
			incoming_statuses &= ~key
	var already_inflicted_with_major_status = false
	for key in status_map:
		if incoming_statuses & key:
			if key < statuses.FREEZE:
				already_inflicted_with_major_status = true
				for _status in active_statuses:
					if _status.status_type & (incoming_statuses & key):
						_status.remaining_turns = 3
						break
			
			if (all_active_effects != 0) and (all_active_effects & key) == key:
				for _status in active_statuses:
					if _status.status_type & (incoming_statuses & key):
						_status.remaining_turns += 3
						break
			else:
				var add_status = status.new()
				add_status.status_type = key
				add_status.setup()
				active_statuses.append(add_status)
				if all_active_effects == 0:
					all_active_effects = key
				else:
					all_active_effects |= key
	if not stored_combatant.is_combatant_enemy:
		parent_reference.get_player_portrait(child_number).update_statuses(parent_reference.get_player(child_number))

func remove_status(statustype):
	pass

func _remove_active_status(type_to_remove: int):
	all_active_effects &= ~type_to_remove 
	for i in range(active_statuses.size() - 1, -1, -1):
		if active_statuses[i].status_type == type_to_remove:
			active_statuses.remove_at(i)
			break

func take_turn(player_portrait: player_portraits = null):
	is_defending = false
	if all_active_effects != null:
		for key in status_map:
			if all_active_effects & key:
				status_map[key].call()
	if active_statuses != null:
		for _status in range(active_statuses.size()):
			active_statuses[_status].remaining_turns -= 1
			if active_statuses[_status].remaining_turns == 0:
				_remove_active_status(active_statuses[_status].status_type)
	if not stored_combatant.is_combatant_enemy:
		player_portrait.update_statuses(self)

# Functions that run if status is active

func _apply_stun(): print("STUN")
func _apply_sleep(): print("SLEEP")
func _apply_shock(): print("SHOCK")
func _apply_poison(): 
	update_health(20, true)

func _apply_burn(): 
	update_health(20, true)
func _apply_freeze(): print("FREEZE")
func _apply_agro(): print("AGRO")
func _apply_momentum(): print("momentum")
func _apply_regen():  print("regen")
func _apply_stun_imm():  print("stun imun")
func stat_does_nothing(): return

# Helper Functions
func obtain_stat(what_stat):
	match what_stat:
		# Attack
		0:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.combatant_stats.attack * ret_stat if (ret_stat != 0) else 1
		# Defense
		1:
			var ret_stat = obtain_stat_alteration(stats.DEFENSE)
			return stored_combatant.combatant_stats.defense * ret_stat if (ret_stat != 0) else 1
		# Evasion
		3:
			var ret_stat = obtain_stat_alteration(stats.EVASION)
			return stored_combatant.combatant_stats.evasion * ret_stat if (ret_stat != 0) else 1
		# Crit Chance
		4:
			var ret_stat = obtain_stat_alteration(stats.CRIT_CHANCE)
			return ret_stat if (ret_stat != 0) else 1
		5: 
			var ret_stat = obtain_stat_alteration(stats.SPEED)
			return stored_combatant.combatant_stats.speed * ret_stat if (ret_stat != 0) else 1
		6:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.combatant_stats.magic * ret_stat if (ret_stat != 0) else 1

func obtain_stat_alteration(what_stat):
	match what_stat:
		# Attack
		0:
			if all_active_effects & statuses.ATTACKup:
				return attack_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return attack_up_down - 0.5
		# Defense
		1:
			if all_active_effects & statuses.DEFENSEup:
				return defense_up_down
			elif all_active_effects & statuses.DEFENSEdown:
				return defense_up_down - 0.5
		# Accuracy
		2:
			if all_active_effects & statuses.ACCURACYdown:
				return accuracy_up_down 
			elif all_active_effects & statuses.ACCURACYdown:
				return accuracy_up_down - 0.5
		# Evasion
		3:
			if all_active_effects & statuses.ATTACKup:
				return evasion_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return evasion_up_down - 0.5
		# Crit Chance
		4:
			if all_active_effects & statuses.ATTACKup:
				return critchance_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return critchance_up_down - 0.5
		# Speed / Slow
		5: 
			if all_active_effects & statuses.SLOW:
				return -20
	return 1

func could_be_selected():
	combatant_sprite.modulate = Color(Color.YELLOW, 0.75)
	currently_selectable = true

func undo_selection():
	combatant_sprite.modulate = Color(Color.WHITE, 0.75)
	currently_selectable = false

func _unhandled_input(event):
	subviewport.push_input(event)

# Makes them clickable, probably will be removed
func create_collision_from_sprite_3d():
	for child in interactable_area.get_children():
		if child is CollisionPolygon3D:
			child.queue_free()

	var texture = combatant_sprite.texture
	if not texture: return
	
	var image = texture.get_image()
	if image.is_compressed():
		var err = image.decompress()
		if err != OK:
			return
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()), 2.0)
	var scale_factor = combatant_sprite.pixel_size
	
	for poly_points in polygons:
		var collision_poly = CollisionPolygon3D.new()
		var adjusted_points = PackedVector2Array()
		var texture_center = Vector2(texture.get_width(), texture.get_height()) / 2.0
		
		for pt in poly_points:
			var new_pt = pt
			
			if combatant_sprite.centered:
				new_pt -= texture_center
			new_pt.y *= -1 
			adjusted_points.append(new_pt * scale_factor)
		
		collision_poly.polygon = adjusted_points
		collision_poly.depth = 0.1 
		interactable_area.add_child(collision_poly)
		
		if not combatant_sprite.centered:
			collision_poly.position.y += (texture.get_height() * scale_factor)

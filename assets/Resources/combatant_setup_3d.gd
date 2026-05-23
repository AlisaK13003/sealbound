extends Node3D

@onready var combatant_name = $Sprite3D2/SubViewport/CombatantUi.get_node("Label")
@onready var combatant_sprite = $Sprite3D
@onready var health_bar = $Sprite3D2/SubViewport/CombatantUi.get_node("TextureProgressBar")
@onready var interactable_area = $Area3D
@onready var attacked_label = $Label3D
@onready var combatant_ui = $Sprite3D2/SubViewport/CombatantUi/Player_Menu
@onready var combatant_ui_area = $Sprite3D2/Area3D

@onready var subviewport = $Sprite3D2/SubViewport
@onready var rng = RandomNumberGenerator.new()

@onready var status_map: Dictionary = {
	statuses.STUN: _apply_stun,
	statuses.SLEEP: _apply_sleep,
	statuses.SHOCK: _apply_shock,
	statuses.POISON: _apply_poison,
	statuses.BURN: _apply_burn,
	statuses.FREEZE: _apply_freeze,
	statuses.SLOW: _apply_slow,
	statuses.AGRO: _apply_agro,
	statuses.ATTACKdown: _apply_atk_down,
	statuses.DEFENSEdown: _apply_def_down,
	statuses.EVASIONdown: _apply_eva_down,
	statuses.CRITCHANCEdown: _apply_crit_down,
	statuses.ACCURACYdown: _apply_acc_down,
	statuses.MOMENTUM: _apply_momentum,
	statuses.REGEN: _apply_regen,
	statuses.STUNIMMUNITY: _apply_stun_imm,
	statuses.ATTACKup: _apply_atk_up,
	statuses.DEFENSEup: _apply_def_up,
	statuses.EVASIONup: _apply_eva_up,
	statuses.CRITCHANCEup: _apply_crit_up
}

func _unhandled_input(event):
	subviewport.push_input(event)

var currently_selectable : bool
var stored_combatant : generic_combatants
var parent_reference
var child_number: int
var is_empty : bool
var is_defending : bool = false
var all_active_effects = 0
var active_statuses : Array[status]

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
	$Sprite3D2/SubViewport/CombatantUi.setup(self)
	
func could_be_selected():
	combatant_sprite.modulate = Color(Color.YELLOW, 0.75)
	currently_selectable = true

func undo_selection():
	combatant_sprite.modulate = Color(Color.WHITE, 0.75)
	currently_selectable = false

func update_health(change_health_value):
	if str(change_health_value) == "MISS":
		attacked_label.text = "MISSED"
	else:
		if is_defending:
			health_bar.value -= floor(change_health_value * 0.4)
			attacked_label.text = str(int(floor(change_health_value * 0.4)))
		else:
			health_bar.value -= floor(change_health_value)
			attacked_label.text = str(int(floor(change_health_value)))
	await get_tree().create_timer(0.5).timeout
	
	attacked_label.text = ""
	if health_bar.value <= 0:
		on_death()
	parent_reference.turn_ended.emit()

func calculate_evasion(entity_being_attacked: generic_combatants, attack_hit_chance = 90):
	if not stored_combatant.is_combatant_enemy:
		return ((stored_combatant.combatant_stats.evasion + 200) / (entity_being_attacked.combatant_stats.evasion + 200)) * attack_hit_chance 
	else:
		return (((stored_combatant.combatant_stats.evasion + 200) / (entity_being_attacked.combatant_stats.evasion + 200)) * attack_hit_chance) * ((stored_combatant.combatant_stats.evasion + 200) / (((stored_combatant.stored_equipment.equipment_stats.evasion) / 2) + 200))

func execute_base_attack(entity_being_attacked: generic_combatants, entity_node):
	var chance_to_hit = calculate_evasion(entity_being_attacked)
	var chance = rng.randf_range(0, 1)
	
	if chance <= chance_to_hit:
		entity_node.handle_status(statuses.BURN)
		return 5 * sqrt((stored_combatant.combatant_stats.attack / (entity_being_attacked.combatant_stats.defense + 1)) * stored_combatant.stored_weapon.weapon_attack) * randf_range(0.95, 1.05)
	else:
		return "MISS"
		
func on_death():
	self.visible = false
	stored_combatant.is_dead = true

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

func take_turn():
	is_defending = false
	if all_active_effects != null:
		print("Enemy: ", self.name, " current flags: ", all_active_effects)
		for key in status_map:
			if all_active_effects & key:
				status_map[key].call()

func execute_defend():
	is_defending = true

func do_nothing_3d(camera, event, event_position, normal, shape_idx):
	if event is InputEventMouseButton and stored_combatant.is_combatant_enemy:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)

func reset_ui():
	combatant_ui.get_parent().reset_ui()

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
	CRITCHANCEup = 1 << 19
}

var conflicts = {
	statuses.ATTACKdown: statuses.ATTACKup,
	statuses.ATTACKup: statuses.ATTACKdown,
	statuses.DEFENSEdown: statuses.DEFENSEup,
	statuses.DEFENSEup: statuses.DEFENSEdown,
	statuses.EVASIONdown: statuses.EVASIONup,
	statuses.EVASIONup: statuses.EVASIONdown,
	statuses.CRITCHANCEdown: statuses.CRITCHANCEup,
	statuses.CRITCHANCEup: statuses.CRITCHANCEdown
}

func handle_status(incoming_statuses):
	for key in conflicts.keys():
		var opposite = conflicts[key]
		if (incoming_statuses & key) and (all_active_effects & opposite):
			_remove_active_status(opposite)
			incoming_statuses &= ~key
	
	for key in status_map:
		if incoming_statuses & key:
			if (all_active_effects != 0) and (all_active_effects & key) == key:
				for _status in active_statuses:
					if _status.status_type & (incoming_statuses & key):
						_status.remaining_turns = 3
						break
			else:
				var add_status = status.new()
				add_status.status_type = key
				active_statuses.append(add_status)
				if all_active_effects == 0:
					all_active_effects = key
				else:
					all_active_effects |= key
					
func _remove_active_status(type_to_remove: int):
	all_active_effects &= ~type_to_remove 
	for i in range(active_statuses.size() - 1, -1, -1):
		if active_statuses[i].status_type == type_to_remove:
			active_statuses.remove_at(i)
			break

func _apply_stun(): print("STUN")
func _apply_sleep(): print("SLEEP")
func _apply_shock(): print("SHOCK")
func _apply_poison(): print("POISON")
func _apply_burn(): print(stored_combatant.combatant_name, " is burned")
func _apply_freeze(): print("FREEZE")
func _apply_slow(): print("SLOW")
func _apply_agro(): print("AGRO")
func _apply_atk_down(): print("Attack Down")
func _apply_def_down(): print("Def down")
func _apply_eva_down(): print("eva down")
func _apply_crit_down(): print("crit down")
func _apply_acc_down(): print("acc down")
func _apply_momentum(): print("momentum")
func _apply_regen():  print("regen")
func _apply_stun_imm():  print("stun imun")
func _apply_atk_up():  print("atck up")
func _apply_def_up(): print("Def up")
func _apply_eva_up():  print("eva up")
func _apply_crit_up():  print("crit up")

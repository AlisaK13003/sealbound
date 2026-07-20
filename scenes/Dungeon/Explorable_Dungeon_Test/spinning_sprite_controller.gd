extends Sprite3D

var going_up: bool = false
var player_collected_me: bool = false

var what_quest_am_i: quest
var should_give_key: bool = false
var is_boss_key: bool = false

var basic_key_sprite: String = "res://assets/tile sheets/Dungeon_Special_Room_Key.png"
var boss_key_sprite: String = "res://assets/tile sheets/Dungeon_Boss_Room_Key.png"

func _setup(quest_: quest = null, is_key_room: bool = false, boss_key: bool = false):
	self.visible = true
	if quest_ != null:
		what_quest_am_i = quest_
		self.texture = quest_.item_to_drop.item_sprite
		self.pixel_size = quest_.item_sprite_pixel_size
	elif is_key_room:
		should_give_key = true
		is_boss_key = boss_key
		if is_boss_key:
			var new_texture = load(boss_key_sprite)
			self.texture = new_texture
		else:
			var new_texture = load(basic_key_sprite)
			self.texture = new_texture

func _physics_process(delta):
	self.rotate(Vector3(0, 1, 0), 1 * delta)
	if going_up:
		self.position.y += 0.1 * delta
		if self.position.y > 1.4:
			going_up = false
	else:
		self.position.y -= 0.1 * delta
		if self.position.y < 0.7:
			going_up = true

func _on_area_3d_body_entered(body):
	if body.is_in_group("3D_Player"): 
		player_collected_me = true
		self.visible = false
		if what_quest_am_i != null:
			for quest_ in GlobalCombatInformation.active_quests:
				if quest_.quest_name == what_quest_am_i.quest_name:
					quest_.does_player_have_special_item = true
					quest_.should_spawn_dungeon_room = false
					
					GlobalCombatInformation.add_item(what_quest_am_i.item_to_drop.get_path_custom())
					StateManager.set_story_state(quest_.state_to_set_upon_completion, true)
					GlobalCombatInformation.dungeon_over()
					break
		elif should_give_key:
			if is_boss_key and not GlobalCombatInformation.holding_boss_key > 1:
				self.visible = false
				GlobalCombatInformation.holding_boss_key += 1
				GlobalCombatInformation.obtained_or_used_key.emit()
			elif not GlobalCombatInformation.holding_basic_room_key:
				self.visible = false
				GlobalCombatInformation.holding_basic_room_key += 1
				GlobalCombatInformation.obtained_or_used_key.emit()

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
		if player_collected_me:
			return
		player_collected_me = true
		self.visible = false
		if what_quest_am_i != null:
			for quest_ in GlobalCombatInformation.active_quests:
				if quest_.quest_name == what_quest_am_i.quest_name:
					quest_.does_player_have_special_item = true
					quest_.should_spawn_dungeon_room = false
					
					GlobalCombatInformation.add_item(what_quest_am_i.item_to_drop.get_path_custom())
					StateManager.set_story_state(quest_.state_to_set_upon_completion, true)
					show_special_item_pickup_dialogue(what_quest_am_i)
					#GlobalCombatInformation.dungeon_over()
					break
		elif should_give_key:
			if is_boss_key and not GlobalCombatInformation.holding_boss_key > 1:
				self.visible = false
				self.queue_free()
				GlobalCombatInformation.holding_boss_key += 1
				GlobalCombatInformation.obtained_or_used_key.emit()
			elif not GlobalCombatInformation.holding_basic_room_key:
				self.visible = false
				self.queue_free()
				GlobalCombatInformation.holding_basic_room_key += 1
				GlobalCombatInformation.obtained_or_used_key.emit()

func show_special_item_pickup_dialogue(quest_: quest) -> void:
	if quest_ == null or quest_.item_to_drop == null:
		return
	if quest_.item_to_drop.item_name != "Lyra's Axe":
		return
	var dungeon_player = get_tree().get_first_node_in_group("3D_Player")
	if dungeon_player != null and dungeon_player.has_method("set_dialogue_movement_locked"):
		dungeon_player.set_dialogue_movement_locked(true)
	Global.show_mc_thought("This must be the axe... Better find a way out of this place now.")
	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system != null and dialogue_system.has_signal("dialogue_closed") and bool(dialogue_system.get("is_active")):
		var unlock_callback = Callable(self, "unlock_pickup_dialogue_player").bind(dungeon_player)
		if not dialogue_system.dialogue_closed.is_connected(unlock_callback):
			dialogue_system.dialogue_closed.connect(unlock_callback, CONNECT_ONE_SHOT)
	else:
		unlock_pickup_dialogue_player(dungeon_player)

func unlock_pickup_dialogue_player(dungeon_player) -> void:
	if dungeon_player != null and is_instance_valid(dungeon_player) and dungeon_player.has_method("set_dialogue_movement_locked"):
		dungeon_player.set_dialogue_movement_locked(false)

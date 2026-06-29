extends Sprite3D

var going_up: bool = false
var player_collected_me: bool = false

var what_quest_am_i: quest

func _setup(quest_: quest):
	what_quest_am_i = quest_
	self.texture = quest_.item_sprite

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
		for quest_ in GlobalCombatInformation.active_quests:
			if quest_.quest_name == what_quest_am_i.quest_name:
				quest_.does_player_have_special_item = true
				quest_.should_spawn_dungeon_room = false
				break

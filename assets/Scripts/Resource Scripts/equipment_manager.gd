extends Resource
class_name equipment

@export var equipment_name : String
@export var equipment_description : String
@export var equipment_sprite: Texture2D

@export_enum("Helmet", "Chestplate", "Boots", "Charm") var equipment_type = 0

@export var equipment_stats : stats

@export var buy_price : int = 0
@export var sell_price: int = 10
@export var stack: int = 1

func get_path_custom():
	if resource_path != "":
		return resource_path
	else:
		return self.get_meta("original_path", "")

func export_to_JSON():
	return {
		"path": get_path_custom(),
		"stack": stack
	}

func return_stuff():
	match equipment_type:
		# Helmet
		0:
			return {
				"name": equipment_name,
				"description": equipment_description,
				"texture": equipment_sprite,
				"health": equipment_stats.health,
				"resistance": equipment_stats.resistance,
				"stack": stack
			}
		# Chestplate
		1:
			return {
				"name": equipment_name,
				"description": equipment_description,
				"texture": equipment_sprite,
				"defense": equipment_stats.defense,
				"health": equipment_stats.health,
				"stack": stack
			}
		# Boots
		2:
			return {
				"name": equipment_name,
				"description": equipment_description,
				"texture": equipment_sprite,
				"speed": equipment_stats.speed,
				"evasion": equipment_stats.evasion,
				"stack": stack
			}
		# Charm
		3:
			return {
				"name": equipment_name,
				"description": equipment_description,
				"texture": equipment_sprite,
				"magic": equipment_stats.magic,
				"luck": equipment_stats.luck,
				"stack": stack
			}

func get_stat_string():
	match equipment_type:
		# Helmet
		0:
			return str(equipment_stats.health) + " Health, " + str(equipment_stats.resistance) + " Resistance"
		# Chestplate
		1:
			return str(equipment_stats.health) + " Health, " + str(equipment_stats.defense) + " Defense"
		# Boots
		2:
			return str(equipment_stats.speed) + " Speed, " + str(equipment_stats.evasion) + " Evasion"
		# Charm
		3:
			return str(equipment_stats.magic) + " Magic, " + str(equipment_stats.luck) + " Luck"

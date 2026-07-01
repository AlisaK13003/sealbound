extends Control

func _setup(character_name):
	var bond_bar: TextureProgressBar = $TextureProgressBar
	
	var bond_info = Global.get_npc_bond_info(character_name)
	#	return {
	#	"exp": bond_exp,
	#	"tier_index": tier_index,
	#	"tier_name": BOND_TIER_NAMES[tier_index],
	#	"last_talk_day": int(bond_data.get("last_talk_day", -1))
	#}
	
	bond_bar.max_value = Global.BOND_TIER_SIZE * (Global.BOND_TIER_NAMES.size() - 1)
	bond_bar.value = bond_info["exp"]
	
	$"GridContainer/Current Bond Exp".text = "Current Bond Exp: " + str(bond_bar.value)
	$"GridContainer/Days since last talked".text = "Days since last talked: " + str(bond_info["last_talk_day"])
	$"GridContainer/Current Tier".text = "Current Bond Tier: " + bond_info["tier_name"]

extends Node2D

@export var entry_id: String = ""   # set this per-book in the Inspector

var player_in_range: bool = false

func _ready() -> void:
	var range_area: Area2D = $Player_In_Range
	range_area.body_entered.connect(_on_player_in_range_body_entered)
	range_area.body_exited.connect(_on_player_in_range_body_exited)
	range_area.area_entered.connect(_on_player_in_range_area_entered)
	range_area.area_exited.connect(_on_player_in_range_area_exited)

func _input(event) -> void:
	if Global.is_in_menu:
		return
	if not player_in_range:
		return
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		read()
		get_viewport().set_input_as_handled()

func read() -> void:
	if entry_id == "":
		push_warning("LoreBook: entry_id not set")
		return
	JournalCodex.unlock(entry_id)
	JournalReader.open(entry_id)

func _on_player_in_range_body_exited(body) -> void:
	if body.is_in_group("Overworld_Player"):
		player_in_range = false

func _on_player_in_range_body_entered(body) -> void:
	print("BODY: ", body.name, " groups: ", body.get_groups())
	if body.is_in_group("Overworld_Player"):
		player_in_range = true
		
func _on_player_in_range_area_entered(area) -> void:
	if area.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_player_in_range_area_exited(area) -> void:
	if area.is_in_group("Overworld_Player"):
		player_in_range = false

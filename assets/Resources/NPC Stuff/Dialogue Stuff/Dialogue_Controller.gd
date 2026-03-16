extends Control

@onready var text_box = $Control/Label
@onready var speaker_text_box = $Control/"Speaker Name"
@onready var choice_container: VBoxContainer = $Choice_Container

var is_speaking: bool
var session_id: int = 0

signal choice_selected(which_choice)
signal dialogue_advanced

func _ready():
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	for child in range(choice_container.get_child_count()):
		choice_container.get_child(child).get_node("Area2D").input_event.connect(dialogue_choice_selected.bind(child))
	
func _on_visibility_changed():
	if visible:
		print("YOU AND I ARE TALKING")
	else:
		print("GO AWAY")	

# message will contain a singular scene, scene_to_pick tells you what scene to choose
# message contains 4 things as of now, speaker, text, portrait, choices

func start_talking(message, scene_to_pick: int):
	$Control.visible = true
	session_id += 1
	var this_session = session_id
	
	var message_to_display
	var selected_choice
	is_speaking = true
	for cur_message in message:
		if this_session != session_id or not is_speaking: return
		if cur_message["speaker"] == "FEMC":
			selected_choice = await dialogue_choices(cur_message["choices"], this_session)
			if this_session != session_id or not is_speaking: return
			continue
		speaker_text_box.text = cur_message["speaker"]
		
		if cur_message["text"] is Array:
			message_to_display = cur_message["text"][selected_choice]
		else:
			message_to_display = cur_message["text"]
			
		while len(message_to_display) > 0 and is_speaking:
			if len(message_to_display) > 2 and message_to_display.substr(0, 3) == "..." :
				text_box.text += "."
				
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
				await get_tree().create_timer(1).timeout
				if this_session != session_id or not is_speaking: return
				text_box.text += "."
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
				await get_tree().create_timer(1).timeout
				if this_session != session_id or not is_speaking: return
				text_box.text += "."
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
			
			if this_session != session_id or not is_speaking: return
			text_box.text += message_to_display[0]
			await get_tree().create_timer(0.05).timeout
			if this_session != session_id or not is_speaking: return
			if len(message_to_display) > 0 and message_to_display[0] == ".":
				await get_tree().create_timer(1).timeout
				if this_session != session_id or not is_speaking: return
				
			message_to_display = message_to_display.substr(1, len(message_to_display) - 1)

		await dialogue_advanced
		
		text_box.text = ""
			
func _input(event):
	if event.is_action_pressed("Confirm"):
		dialogue_advanced.emit()
#	  "speaker": "FEMC",
#	  "text": "Greetings! Need a quest?",
#	  "portrait": "npc_happy",
#	  "choices": ["Barely", "Not Really", "Who are you?"]

func dialogue_choices(choices, this_session):
	var selected_choice
	choice_container.visible = true
	$Control.visible = false

	for choice in range(len(choices)):
		choice_container.get_child(choice).get_node("Label").text = choices[choice]
	
	selected_choice = await choice_selected
	if this_session != session_id or not is_speaking: return
	choice_container.visible = false
	$Control.visible = true
	
	return selected_choice

func dialogue_choice_selected(_viewport, event, _shape_idx, which_choice):
	if event.is_action_pressed("Mouse_Left_Click"):
		print("SELECTED THIS OPTION")
		choice_selected.emit(which_choice)

func clear_text_box():
	speaker_text_box.text = ""
	text_box.text = ""
	is_speaking = false
	$Control.visible = false
	choice_container.visible = false
	choice_selected.emit()

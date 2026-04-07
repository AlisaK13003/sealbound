extends Control

@onready var text_box = $Control/Label
@onready var speaker_text_box = $Control/"Speaker Name"
@onready var choice_container: VBoxContainer = $Choice_Container

var is_speaking: bool
var session_id: int = 0

signal choice_selected(which_choice)
signal dialogue_advanced

# 2 things are broken, if you spam open and close the dialogue it breaks, so removing the options to prematurely exit dialogue fixes that
# Also spamming open / close doesn't reset the walkaway timer, so stopping early closing also fixes this
# Basically most problems can be fixed by removing the ability to close out early

func _ready():
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	for child in range(choice_container.get_child_count()):
		choice_container.get_child(child).get_node("Area2D").input_event.connect(dialogue_choice_selected.bind(child))

# message will contain a singular scene, scene_to_pick tells you what scene to choose
# message contains 4 things as of now, speaker, text, portrait, choices
# 	Portrait is not set up, could be set up either by: storing portrait as a filepath to load it from or just the filename and parsing to file 
func start_talking(message, _scene_to_pick: int):
	$Control.visible = true
	
	var message_to_display
	var selected_choice
	is_speaking = true
	for cur_message in message:
		if not is_speaking: return
		# If player is set to talk, set up their dialogue choices
		if cur_message["speaker"] == "FEMC":
			selected_choice = await dialogue_choices(cur_message["choices"])
			if not is_speaking: return
			continue
		speaker_text_box.text = cur_message["speaker"]
		
		if cur_message["text"] is Array:
			message_to_display = cur_message["text"][selected_choice]
		else:
			message_to_display = cur_message["text"]
			
		while len(message_to_display) > 0 and is_speaking:
			# Makes it so if ... is present have it slowly print out
			if len(message_to_display) > 2 and message_to_display.substr(0, 3) == "..." :
				text_box.text += "."
				
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
				await get_tree().create_timer(1).timeout
				if not is_speaking: return
				text_box.text += "."
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
				await get_tree().create_timer(1).timeout
				if not is_speaking: return
				text_box.text += "."
				message_to_display = message_to_display.substr(1, len(message_to_display) - 1)
			
			if not is_speaking: return
			# "Slowly" append each character to the string
			text_box.text += message_to_display[0]
			await get_tree().create_timer(0.05).timeout
			if not is_speaking: return
			
			# If last appended character is '.' wait a second to mimic sentence pauses
			if len(message_to_display) > 0 and message_to_display[0] == ".":
				await get_tree().create_timer(1).timeout
				if not is_speaking: return
			
			# Treats string as a queue
			message_to_display = message_to_display.substr(1, len(message_to_display) - 1)

		await dialogue_advanced
		
		text_box.text = ""
			
func _input(event):
	if event.is_action_pressed("Confirm"):
		dialogue_advanced.emit()

# Sets up the dialogue options on the screen to 
func dialogue_choices(choices):
	var selected_choice
	choice_container.visible = true
	$Control.visible = false

	for choice in range(len(choices)):
		choice_container.get_child(choice).get_node("Label").text = choices[choice]
		choice_container.get_child(choice).visible = true
	
	selected_choice = await choice_selected
	if not is_speaking: return
	choice_container.visible = false
	$Control.visible = true
	
	for choice in range(len(choices)):
		choice_container.get_child(choice).visible = false
	
	return selected_choice

# When prompted with a dialogue choice, announce that they've made a choice
func dialogue_choice_selected(_viewport, event, _shape_idx, which_choice):
	if event.is_action_pressed("Mouse_Left_Click"):
		choice_selected.emit(which_choice)

func _on_visibility_changed():
	#if visible:
		#print("YOU AND I ARE TALKING")
	#else:
		#print("GO AWAY")	
	pass
# For testing purposes
# Upon cancelling dialogue, exit out and clear everything
func clear_text_box():
	speaker_text_box.text = ""
	text_box.text = ""
	is_speaking = false
	$Control.visible = false
	choice_container.visible = false
	choice_selected.emit()

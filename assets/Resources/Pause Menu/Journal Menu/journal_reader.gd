extends CanvasLayer

@onready var title_label: Label = $Entry/VBoxContainer/Title
@onready var body_label: RichTextLabel = $Entry/VBoxContainer/Body
@onready var prev_button: Button = $Entry/VBoxContainer/Buttons/Prev
@onready var next_button: Button = $Entry/VBoxContainer/Buttons/Next
@onready var close_button: Button = $Entry/VBoxContainer/Buttons/Close

var pages: Array = []
var page_index: int = 0

func _ready() -> void:
	visible = false
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	close_button.pressed.connect(close)

func open(entry_id: String) -> void:
	var entry: Dictionary = JournalCodex.get_entry(entry_id)
	if entry.is_empty():
		push_warning("JournalReader: no entry '%s'" % entry_id)
		return
	title_label.text = str(entry.get("title", ""))
	pages = entry.get("pages", [])
	page_index = 0
	_refresh()
	visible = true
	# Mirror the shop's freeze pattern so the player can't walk while reading:
	Global.is_in_menu = true
	Global.is_paused = true

func close() -> void:
	visible = false
	Global.is_in_menu = false
	Global.is_paused = false

func _refresh() -> void:
	if pages.is_empty():
		body_label.text = ""
		return
	body_label.text = str(pages[page_index])
	prev_button.visible = page_index > 0
	next_button.visible = page_index < pages.size() - 1

func _on_prev() -> void:
	if page_index > 0:
		page_index -= 1
		_refresh()

func _on_next() -> void:
	if page_index < pages.size() - 1:
		page_index += 1
		_refresh()

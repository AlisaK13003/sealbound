extends Node

const LORE_PATH := "res://assets/Resources/Lore/lore_entries.json"

var entries: Dictionary = {}          # id -> {title, category, pages}
var entry_order: Array[String] = []   # preserves file order for the journal list
var unlocked: Dictionary = {}         # id -> true

func _ready() -> void:
	_load_entries()

func _load_entries() -> void:
	var file := FileAccess.open(LORE_PATH, FileAccess.READ)
	if file == null:
		push_warning("JournalCodex: could not open %s" % LORE_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or not parsed.has("entries"):
		return
	for entry in parsed["entries"]:
		var id := str(entry["id"])
		entries[id] = entry
		entry_order.append(id)

# Returns true only the FIRST time an entry is unlocked (useful later for a "New Lore!" popup).
func unlock(id: String) -> bool:
	if not entries.has(id):
		push_warning("JournalCodex: unknown entry '%s'" % id)
		return false
	if unlocked.has(id):
		return false
	unlocked[id] = true
	return true

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func get_entry(id: String) -> Dictionary:
	return entries.get(id, {})

func get_unlocked_entries() -> Array:
	var result: Array = []
	for id in entry_order:
		if unlocked.has(id):
			result.append(entries[id])
	return result

# Save/load hooks (used in Part 2C)
func export_to_json() -> Dictionary:
	return { "unlocked": unlocked.keys() }

func load_from_json(data: Dictionary) -> void:
	unlocked.clear()
	for id in data.get("unlocked", []):
		unlocked[str(id)] = true

func clear() -> void:
	unlocked.clear()

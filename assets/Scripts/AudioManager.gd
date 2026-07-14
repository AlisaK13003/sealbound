extends Node

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer 
var tile_sfx: AudioStreamPlayer

const CONFIRM_CLICK: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/013_Confirm_03.wav")
const CANCEL_CLICK: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/029_Decline_09.wav")
const SCROLL: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/001_Hover_01.wav")
const SCROLL_CLICK: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/001_Hover_01.wav")
const MENU_OPEN: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/092_Pause_04.wav")
const MENU_CLOSE: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/098_Unpause_04.wav")

const BATTLE_MUSIC: AudioStream = preload("res://assets/Audio/BGM/Battle_Music/[FC] Anomaly Field.ogg")
const BOSS_BATTLE_MUSIC: AudioStream = preload("res://assets/Audio/BGM/Battle_Music/[FC] Like FF Battle .ogg")

const BATTLE_HEAL: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/02_Heal_02.wav")
const BATTLE_TAKE_DAMAGE: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/15_Impact_flesh_02.wav")
const BATTLE_DEAL_DAMAGE: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/22_Slash_04.wav")

const BATTLE_DEF_UP: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/17_Def_buff_01.wav")
const BATTLE_ATK_UP: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/16_Atk_buff_04.wav")
const BATTLE_GENERIC_STAT: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/21_Debuff_01.wav")

const ENCOUNTER: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/55_Encounter_02.wav")

const USE_ITEM: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/051_use_item_01.wav")

const BUY_SELL_SOMETHING: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/079_Buy_sell_01.wav")

const STATUS_SOUND: AudioStream = preload("res://assets/Audio/UI_SFX/BATTLE_SFX/46_Poison_01.wav")


const CREEPY_DUNGEON_BGM: AudioStream = preload("res://assets/Audio/BGM/Battle_Music/HeatOfBattle.ogg")
const FOREST_DUNGEON_BGM: AudioStream = preload("res://assets/Audio/BGM/Battle_Music/Garbage Patch.ogg")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	bgm_player = AudioStreamPlayer.new()
	
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	bgm_player.finished.connect(_on_audio_finished)
	
	tile_sfx = AudioStreamPlayer.new()
	tile_sfx.name = "Tile_SFXPlayer"
	tile_sfx.bus = "TILE"
	add_child(tile_sfx)
	

func _on_audio_finished():
	bgm_player.play()

func play_ui_sound(stream: AudioStream) -> void:
	if not stream:
		return
		
	sfx_player.stop()
	sfx_player.stream = stream
	sfx_player.play()

func play_tile_sound(stream: AudioStream) -> void:
	if not stream:
		return
	if tile_sfx.stream == stream and tile_sfx.playing:
		return
	tile_sfx.stop()
	tile_sfx.stream = stream
	tile_sfx.play()

func play_bgm(stream: AudioStream, override: bool = false) -> void:
	if not stream:
		return
	if not override:
		if bgm_player.stream == stream and bgm_player.playing:
			return
		
	bgm_player.stop()
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func restart_bgm():
	bgm_player.play()

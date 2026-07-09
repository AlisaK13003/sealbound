extends Node

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer 
var tile_sfx: AudioStreamPlayer

const CONFIRM_CLICK: AudioStream = null
const CANCEL_CLICK: AudioStream = null
const SCROLL: AudioStream = preload("res://assets/Audio/UI SFX_MENU_Scroll.ogg")
const SCROLL_CLICK: AudioStream = preload("res://assets/Audio/UI SFX_MENU_Scroll.ogg")
const MENU_OPEN: AudioStream = preload("res://assets/Audio/UI SFX_InGameMenu_Open.ogg")
const MENU_CLOSE: AudioStream = preload("res://assets/Audio/UI SFX_InGameMenu_Close.ogg")

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

func play_bgm(stream: AudioStream) -> void:
	if not stream:
		return
		
	if bgm_player.stream == stream and bgm_player.playing:
		return
		
	bgm_player.stop()
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func restart_bgm():
	bgm_player.play()

class_name AudioManager
extends Node
## AudioManager
## Plays the original Burnin' Rubber 3 WAV sound effects and music.

const SFX_ROOT := "res://assets/Shared/Audio/"
const MENU_SFX_ROOT := "res://assets/Menu/Audio/"

var sound_enabled: bool = true
var music_player: AudioStreamPlayer
var sfx_players: Array = []

func _ready() -> void:
	sound_enabled = MainManager.sound_enabled if MainManager != null else true
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

func set_enabled(on: bool) -> void:
	sound_enabled = on
	if not on:
		music_player.stop()

func _process(_delta: float) -> void:
	# cleanup finished sfx players
	for i in range(sfx_players.size() - 1, -1, -1):
		var p: AudioStreamPlayer = sfx_players[i]
		if not is_instance_valid(p) or not p.playing:
			if is_instance_valid(p):
				p.queue_free()
			sfx_players.pop_at(i)

func play(name: String) -> void:
	if not sound_enabled or name.is_empty():
		return
	var path := _sfx_path(name)
	if path.is_empty():
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = 0.0
	add_child(p)
	p.play()
	sfx_players.append(p)

func play_music(path: String) -> void:
	if not sound_enabled:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	if music_player != null:
		music_player.stop()

func _sfx_path(name: String) -> String:
	# menu sfx
	if name == "button" or name == "button_rollover":
		return MENU_SFX_ROOT + ("ButtonPressed_SFX.wav" if name == "button" else "ButtonRollover_SFX.wav")
	if name == "dialog":
		return MENU_SFX_ROOT + "Dialog_SFX.wav"
	# shared sfx
	var map := {
		"machine_gun": "MachineGun",
		"mini_gun": "MiniGun",
		"main_gun": "MainGun1",
		"rocket": "RocketPodLaunch",
		"rocket_explosion": "RocketPodExplosion",
		"explosion": "Explosion",
		"grenade": "GrenadeLauncher1",
		"grenade_explosion": "GrenadeExplosion",
		"mine": "Mine1",
		"nitro": "NitroStart",
		"pickup": "PickupGeneric",
		"pickup_cash": "PickupCash",
		"pickup_repair": "PickUpCarRepair",
		"crash": "Crash1",
		"hit": "HitDefault1",
		"start": "StartSound1",
		"result": "Result",
		"challenge_complete": "ChallengeCompleted",
		"challenge_failed": "ChallengeFailed",
	}
	var base: String = map.get(name, name)
	# original assets use mixed naming: some have "_SFX" suffix, some don't
	if ResourceLoader.exists(SFX_ROOT + base + "_SFX.wav"):
		return SFX_ROOT + base + "_SFX.wav"
	if ResourceLoader.exists(SFX_ROOT + base + ".wav"):
		return SFX_ROOT + base + ".wav"
	return ""

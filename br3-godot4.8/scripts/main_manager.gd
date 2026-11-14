class_name MainManager
extends Node
## MainManager
## Root controller: manages game state, UI screens and the 3D race scene.

const SAVE_PATH := "user://br3_save.json"

var cash: int = 10000
var owned_cars: Array = ["BMW"]
var unlocked_tracks: Array = ["CityTrack1"]
var completed_tracks: Array = []
var selected_car: String = "BMW"
var selected_track: String = "CityTrack1"
var sound_enabled: bool = true

var ui: UIManager
var race: Node3D
var race_script: Race
var ui_layer: CanvasLayer

func _ready() -> void:
	load_save()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui = UIManager.new()
	ui_layer.add_child(ui)
	ui.start_race.connect(_on_start_race)
	ui.back_to_main.connect(func(): ui.show_main_menu())
	ui.quit_game.connect(func(): get_tree().quit())

func _on_start_race(track_name: String, car_name: String) -> void:
	selected_track = track_name
	selected_car = car_name
	# hide UI
	if ui != null:
		ui.visible = false
	# create race scene
	if race == null:
		race = Node3D.new()
		race.name = "Race"
		add_child(race)
		race_script = Race.new()
		race.add_child(race_script)
		race_script.finished.connect(_on_race_finished)
	if race_script != null and race_script.is_instance_valid():
		race_script.start_race(selected_track, selected_car)

func _on_race_finished(result: Dictionary) -> void:
	# apply rewards if completed
	if result.get("completed", false):
		var track_name: String = result.get("track", "")
		if not completed_tracks.has(track_name):
			completed_tracks.append(track_name)
		var info := GameData.get_track(track_name)
		var rewards: String = info.get("Rewards", "")
		_apply_rewards(rewards, result)
		cash += int(info.get("PrizeMoney", "0"))
	save_save()
	# back to UI
	if ui != null:
		ui.visible = true
		ui.show_main_menu()

func _apply_rewards(rewards: String, result: Dictionary) -> void:
	if rewards.is_empty():
		return
	for part in rewards.split(","):
		var p := part.strip_edges()
		if p.is_empty():
			continue
		var eq := p.find("=")
		if eq < 0:
			continue
		var key := p.substr(0, eq).strip_edges()
		var val := p.substr(eq + 1).strip_edges()
		if key == "UnlockTrack":
			if not unlocked_tracks.has(val):
				unlocked_tracks.append(val)
		elif key == "UnlockCar":
			if not owned_cars.has(val):
				owned_cars.append(val)
		elif key == "UnlockPrimaryWeapon" or key == "UnlockSecondaryWeapon":
			# weapons are handled in-race; just note
			pass
		elif key == "UnlockBodyKit" or key == "UnlockUpgrade":
			pass

func is_track_unlocked(name: String) -> bool:
	return unlocked_tracks.has(name)

func is_car_owned(name: String) -> bool:
	return owned_cars.has(name)

# ---------------------------------------------------------------- save
func save_save() -> void:
	var data := {
		"cash": cash,
		"owned_cars": owned_cars,
		"unlocked_tracks": unlocked_tracks,
		"completed_tracks": completed_tracks,
		"selected_car": selected_car,
		"selected_track": selected_track,
		"sound_enabled": sound_enabled,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func load_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var s := f.get_as_text()
	if s.is_empty():
		return
	var data: Variant = JSON.parse_string(s)
	if data is Dictionary:
		cash = int(data.get("cash", 10000))
		owned_cars = data.get("owned_cars", ["BMW"])
		unlocked_tracks = data.get("unlocked_tracks", ["CityTrack1"])
		completed_tracks = data.get("completed_tracks", [])
		selected_car = data.get("selected_car", "BMW")
		selected_track = data.get("selected_track", "CityTrack1")
		sound_enabled = bool(data.get("sound_enabled", true))
	AudioManager.set_enabled(sound_enabled)

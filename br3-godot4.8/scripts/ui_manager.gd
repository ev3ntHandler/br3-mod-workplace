class_name UIManager
extends Control
## UIManager
## Builds all 2D menu screens using the original Burnin' Rubber 3 textures.

const TEX := "res://assets/Menu/Textures/"

var screens: Dictionary = {}
var current: String = ""

signal start_race(track_name: String, car_name: String)
signal back_to_main()
signal quit_game()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	show_main_menu()

# ---------------------------------------------------------------- helpers
func make_bg(texture_path: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = load(texture_path)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.anchors_preset = Control.PRESET_FULL_RECT
	return tr

func make_button(label: String, normal: String, rollover: String, pressed: String, callback: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(220, 64)
	b.flat = true
	var tr := TextureRect.new()
	tr.texture = load(normal)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchors_preset = Control.PRESET_FULL_RECT
	b.add_child(tr)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	b.add_child(lbl)
	b.pressed.connect(func():
		if rollover != "":
			tr.texture = load(rollover)
		AudioManager.play("button")
		callback.call()
	)
	b.mouse_entered.connect(func():
		if rollover != "":
			tr.texture = load(rollover)
			AudioManager.play("button_rollover")
	)
	b.mouse_exited.connect(func():
		tr.texture = load(normal)
	)
	return b

func clear_screens() -> void:
	for s in screens:
		var sc: Control = screens[s]
		if is_instance_valid(sc):
			sc.queue_free()
	screens.clear()

func show_screen(name: String) -> void:
	if current == name and screens.has(name):
		return
	clear_screens()
	current = name
	var sc: Control = screens[name]
	if sc == null:
		return
	add_child(sc)

# ---------------------------------------------------------------- main menu
func show_main_menu() -> void:
	var sc := Control.new()
	sc.name = "MainMenu"
	sc.anchors_preset = Control.PRESET_FULL_RECT
	sc.add_child(make_bg(TEX + "Main/InitializingBG_Texture.png"))
	# logo
	var logo := TextureRect.new()
	logo.texture = load(TEX + "Logo/BR3Logo_Texture.png")
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.anchor_left = 0.5
	logo.anchor_top = 0.06
	logo.anchor_right = 0.5
	logo.anchor_bottom = 0.16
	logo.offset_left = -180
	logo.offset_right = 180
	logo.offset_top = 20
	logo.offset_bottom = 80
	sc.add_child(logo)
	var vb := VBoxContainer.new()
	vb.position = Vector2(430, 240)
	vb.custom_minimum_size = Vector2(420, 0)
	vb.add_theme_constant_override("separation", 18)
	sc.add_child(vb)
	vb.add_child(make_button(GameData.get_text("StartButton", "START"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_track_selection()))
	vb.add_child(make_button(GameData.get_text("CarsTabName", "CARS"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_car_selection()))
	vb.add_child(make_button("OPTIONS",
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_options()))
	vb.add_child(make_button("HELP",
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_help()))
	vb.add_child(make_button("QUIT",
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): quit_game.emit()))
	# footer
	var footer := Label.new()
	footer.text = GameData.get_text("Footer", "BURNIN' RUBBER 3 (C) XFORM 2009-2020.")
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_bottom = 0.02
	footer.offset_bottom = 10
	sc.add_child(footer)
	screens["MainMenu"] = sc
	show_screen("MainMenu")

# ---------------------------------------------------------------- track selection
func show_track_selection() -> void:
	var sc := Control.new()
	sc.name = "TrackSelection"
	sc.anchors_preset = Control.PRESET_FULL_RECT
	sc.add_child(make_bg(TEX + "Main/InitializingBG_Texture.png"))
	var title := Label.new()
	title.text = GameData.get_text("TrackSelectionTabName", "WORLD DOMINATION")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.position = Vector2(430, 30)
	title.size = Vector2(420, 50)
	sc.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 100)
	scroll.size = Vector2(1160, 480)
	sc.add_child(scroll)
	var list := FlowContainer.new()
	list.add_theme_constant_override("h_separation", 12)
	list.add_theme_constant_override("v_separation", 12)
	scroll.add_child(list)
	var tracks := GameData.list_tracks()
	for t in tracks:
		var name: String = t["TrackName"]
		var unlocked := MainManager.is_track_unlocked(name)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 110)
		btn.flat = true
		var tr := TextureRect.new()
		var tag_tex := TEX + "Main/TrackNormal_Texture.png"
		if unlocked:
			tag_tex = TEX + "Main/TrackSelected_Texture.png"
		else:
			tag_tex = TEX + "Main/LockedTag_Texture.png"
		tr.texture = load(tag_tex)
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.anchors_preset = Control.PRESET_FULL_RECT
		btn.add_child(tr)
		var lbl := Label.new()
		lbl.text = name + "  [" + t["GameMode"] + "]"
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		btn.add_child(lbl)
		var desc := Label.new()
		desc.text = t["Description"]
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		desc.anchors_preset = Control.PRESET_FULL_RECT
		btn.add_child(desc)
		btn.pressed.connect(func():
			if unlocked:
				MainManager.selected_track = name
				show_car_selection()
		)
		list.add_child(btn)
	# back button
	var back := make_button(GameData.get_text("BackButton", "BACK"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_main_menu())
	back.position = Vector2(430, 620)
	back.size = Vector2(220, 64)
	sc.add_child(back)
	screens["TrackSelection"] = sc
	show_screen("TrackSelection")

# ---------------------------------------------------------------- car selection
func show_car_selection() -> void:
	var sc := Control.new()
	sc.name = "CarSelection"
	sc.anchors_preset = Control.PRESET_FULL_RECT
	sc.add_child(make_bg(TEX + "Hangar/Hangar_Texture.png"))
	var title := Label.new()
	title.text = GameData.get_text("CarsTabName", "CARS")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.position = Vector2(430, 30)
	title.size = Vector2(420, 50)
	sc.add_child(title)
	# car preview (skin texture)
	var preview := TextureRect.new()
	var car := MainManager.selected_car
	if car != "":
		preview.texture = load("res://assets/Cars/SkinTextures/" + car + "Skin1_Texture.png")
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.position = Vector2(60, 100)
	preview.size = Vector2(420, 320)
	sc.add_child(preview)
	# car list
	var list := VBoxContainer.new()
	list.position = Vector2(520, 100)
	list.size = Vector2(420, 420)
	list.add_theme_constant_override("separation", 8)
	sc.add_child(list)
	for c in GameData.get_available_cars():
		var owned := MainManager.is_car_owned(c)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 52)
		btn.flat = true
		var lbl := Label.new()
		lbl.text = c
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		btn.add_child(lbl)
		if c == MainManager.selected_car:
			lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		var car_name: String = c
		btn.pressed.connect(func():
			if owned:
				MainManager.selected_car = car_name
				show_car_selection()
		)
		list.add_child(btn)
	# start button
	var track := MainManager.selected_track
	var start := make_button(GameData.get_text("StartButton", "START"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): start_race.emit(track, MainManager.selected_car))
	start.position = Vector2(430, 560)
	start.size = Vector2(220, 64)
	sc.add_child(start)
	var back := make_button(GameData.get_text("BackButton", "BACK"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_track_selection())
	back.position = Vector2(680, 560)
	back.size = Vector2(220, 64)
	sc.add_child(back)
	screens["CarSelection"] = sc
	show_screen("CarSelection")

# ---------------------------------------------------------------- options
func show_options() -> void:
	var sc := Control.new()
	sc.name = "Options"
	sc.anchors_preset = Control.PRESET_FULL_RECT
	sc.add_child(make_bg(TEX + "Main/InitializingBG_Texture.png"))
	var title := Label.new()
	title.text = "OPTIONS"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.position = Vector2(430, 30)
	title.size = Vector2(420, 50)
	sc.add_child(title)
	var vb := VBoxContainer.new()
	vb.position = Vector2(430, 120)
	vb.custom_minimum_size = Vector2(420, 0)
	vb.add_theme_constant_override("separation", 16)
	sc.add_child(vb)
	var sound_on := Button.new()
	sound_on.custom_minimum_size = Vector2(420, 64)
	sound_on.flat = true
	var sound_lbl := Label.new()
	sound_lbl.text = "SOUND: " + ("ON" if MainManager.sound_enabled else "OFF")
	sound_lbl.anchors_preset = Control.PRESET_FULL_RECT
	sound_lbl.add_theme_font_size_override("font_size", 22)
	sound_on.add_child(sound_lbl)
	sound_on.pressed.connect(func():
		MainManager.sound_enabled = not MainManager.sound_enabled
		AudioManager.set_enabled(MainManager.sound_enabled)
		show_options()
	)
	vb.add_child(sound_on)
	var back := make_button(GameData.get_text("BackButton", "BACK"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_main_menu())
	back.position = Vector2(430, 620)
	back.size = Vector2(220, 64)
	sc.add_child(back)
	screens["Options"] = sc
	show_screen("Options")

# ---------------------------------------------------------------- help
func show_help() -> void:
	var sc := Control.new()
	sc.name = "Help"
	sc.anchors_preset = Control.PRESET_FULL_RECT
	sc.add_child(make_bg(TEX + "Main/InitializingBG_Texture.png"))
	var title := Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.position = Vector2(430, 30)
	title.size = Vector2(420, 50)
	sc.add_child(title)
	var txt := Label.new()
	txt.text = "W / S : Accelerate / Brake\nA / D : Steer Left / Right\nSPACE : Nitro Boost\nZ : Fire Primary Weapon\nX : Fire Secondary Weapon\nC : Toggle Rear Camera\nESC : Pause"
	txt.add_theme_font_size_override("font_size", 22)
	txt.position = Vector2(160, 120)
	txt.size = Vector2(960, 300)
	sc.add_child(txt)
	var back := make_button(GameData.get_text("BackButton", "BACK"),
		TEX + "Main/TrackNormal_Texture.png",
		TEX + "Main/TrackRollover_Texture.png",
		TEX + "Main/TrackSelected_Texture.png",
		func(): show_main_menu())
	back.position = Vector2(430, 620)
	back.size = Vector2(220, 64)
	sc.add_child(back)
	screens["Help"] = sc
	show_screen("Help")

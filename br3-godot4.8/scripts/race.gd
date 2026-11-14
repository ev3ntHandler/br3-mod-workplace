extends Node3D
## Race
## The 3D race scene: builds the track from the original FBX tile library and
## event data, spawns the player and AI cars, and runs the game loop.

signal finished(result: Dictionary)

const SHADER_STREET := """
shader_type spatial;
uniform sampler2D base_tex;
uniform sampler2D lightmap_tex;
void fragment() {
	vec4 base = texture(base_tex, UV);
	vec4 lm = texture(lightmap_tex, UV2);
	OUTPUT = vec4(base.rgb * lm.rgb, base.a);
}
"""

var world: String = ""
var track_num: String = ""
var track_data: Dictionary = {}
var track_info: Dictionary = {}
var ai_paths: Dictionary = {}
var global_path: Array[Vector3] = []
var cars: Array[Car] = []
var player: Car
var pickups: Array = []
var traffic: Array = []
var hud: Control
var camera: Camera3D
var timer: float = 0.0
var target_time: float = 120.0
var target_damage: float = 0.0
var game_mode: String = "Race"
var game_over: bool = false
var cam_reversed: bool = false
var skybox_group: Node3D
var env: Environment
var fbx_cache: Dictionary = {}
var mat_cache: Dictionary = {}
var shader_cache: Dictionary = {}
var explosion_texture: Texture2D
var finish_line: Node3D
var path_points: Array = []  # for progress/finish

func start_race(track_name: String, car_name: String) -> void:
	# parse track name: e.g. CityTrack1 -> world=City, num=1
	var idx := track_name.find("Track")
	if idx < 0:
		push_error("Race: invalid track name " + track_name)
		return
	world = track_name.substr(0, idx)
	track_num = track_name.substr(idx + 5)
	# load data
	track_data = GameData.load_track_events(world, track_num)
	ai_paths = GameData.load_ai_paths(world)
	game_mode = str(track_data.get("GameMode", "Race"))
	# Target comes from TrackInfo.txt (time limit for Race, damage target for Rampage)
	track_info = GameData.get_track(track_name)
	var target_val := float(track_info.get("Target", 0))
	if game_mode == "Rampage":
		target_damage = target_val
		target_time = 120.0
	else:
		target_damage = 0.0
		target_time = target_val / 1000.0
	if target_time <= 0.0:
		target_time = 120.0
	# clear previous
	_clear_scene()
	_setup_environment()
	_build_track()
	_build_ai_path()
	_spawn_cars(car_name)
	_place_pickups()
	_place_traffic()
	_setup_camera()
	_setup_hud()
	timer = 0.0
	game_over = false
	# race music
	AudioManager.play_music("res://assets/Tracks/" + world + "/Audio/" + world + "_Music.wav")

func _clear_scene() -> void:
	for c in cars:
		if is_instance_valid(c):
			c.queue_free()
	cars.clear()
	for p in pickups:
		if is_instance_valid(p):
			p.queue_free()
	pickups.clear()
	for t in traffic:
		if is_instance_valid(t):
			t.queue_free()
	traffic.clear()
	skybox_group = null
	finish_line = null
	camera = null
	hud = null
	# free all children (track, lights, environment, camera, hud, etc.)
	for child in get_children():
		child.queue_free()

func _setup_environment() -> void:
	# lighting
	var dir := DirectionalLight3D.new()
	dir.rotation = Vector3(PI / 4, 0.3, 0.0)
	dir.light_energy = 1.2
	add_child(dir)
	# environment with fog
	env = Environment.new()
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 0.5
	if track_data.get("Fog", false):
		env.fog_enabled = true
		env.fog_light_color = Color(track_data.get("FogColor", [156,153,116]))
		var fog_arr: Array = track_data.get("FogRange", [25, 600])
		env.fog_depth_near = float(fog_arr[0])
		env.fog_depth_far = float(fog_arr[1])
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.5, 0.6)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	# skybox
	var sky_name: String = str(track_data.get("Skybox", ""))
	if not sky_name.is_empty():
		skybox_group = _instantiate_prefix("Skyboxes.fbx", "res://assets/Shared/3d/Skyboxes.fbx", "Skybox" + sky_name, Vector3.ZERO)
		if skybox_group != null:
			add_child(skybox_group)
	# explosion texture
	explosion_texture = load("res://assets/Shared/Textures/ParticleExplosion1_Texture.png")

func _get_fbx(path: String) -> PackedScene:
	if fbx_cache.has(path):
		return fbx_cache[path]
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("Race: cannot load FBX " + path)
		return null
	fbx_cache[path] = ps
	return ps

func _clean_name(name: String) -> String:
	# FBX nodes may carry a "Model::" prefix; strip it for matching.
	if name.begins_with("Model::"):
		return name.substr(7)
	return name

func _instantiate_prefix(label: String, path: String, prefix: String, position: Vector3) -> Node3D:
	var ps := _get_fbx(path)
	if ps == null:
		return null
	var inst := ps.instantiate()
	var group := Node3D.new()
	group.name = label
	# The original game clones <type>_Root and its children.
	var root_name := prefix + "_Root"
	var root_node: Node3D = null
	for node in inst.get_children():
		if _clean_name(node.name) == root_name:
			root_node = node
			break
	if root_node == null:
		# fallback: match by prefix if no explicit _Root
		for node in inst.get_children():
			if _clean_name(node.name).begins_with(prefix):
				root_node = node
				break
	if root_node == null:
		return null
	root_node.reparent(group, true)
	group.transform.origin = position
	return group

# ---------------------------------------------------------------- track building
func _build_track() -> void:
	var world_node := Node3D.new()
	world_node.name = "World"
	add_child(world_node)
	var assets_path := "res://assets/Tracks/" + world + "/3d/" + world + "Assets.fbx"
	var tex_dir := "res://assets/Tracks/" + world + "/Textures/"
	var build: Array[Dictionary] = track_data.get("build", [])
	for tile in build:
		var type: String = tile.get("type", "")
		if type.is_empty():
			continue
		var pos := to_godot(tile.get("position", Vector3.ZERO))
		var group := _instantiate_prefix(type, assets_path, type, pos)
		if group != null:
			_apply_tile_textures(group, type, tex_dir)
			world_node.add_child(group)
		# objects, pickups, traffic handled separately

func _apply_tile_textures(group: Node3D, tile_type: String, tex_dir: String) -> void:
	_apply_tile_textures_recursive(group, tile_type, tex_dir)

func _apply_tile_textures_recursive(node: Node, tile_type: String, tex_dir: String) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh: ArrayMesh = child.mesh
			if mesh != null:
				_apply_mesh_texture(child, tile_type, tex_dir)
		_apply_tile_textures_recursive(child, tile_type, tex_dir)

func _apply_mesh_texture(node: MeshInstance3D, tile_type: String, tex_dir: String) -> void:
	var name: String = _clean_name(node.name)
	if name.find("Street") >= 0:
		_apply_street_material(node, tile_type, tex_dir)
	elif name.find("Buildings") >= 0:
		node.material_override = _get_standard_mat(tex_dir + world + "Buildings_Texture.png", 0.8)
	elif name.find("Transparent") >= 0:
		var m := _get_standard_mat(tex_dir + world + "Transparent_Texture.png", 0.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = m
	elif name.find("Waves") >= 0:
		node.material_override = _get_standard_mat(tex_dir + "Waves_Texture.png", 0.6)
	elif name.find("Misc") >= 0:
		node.material_override = _get_standard_mat("res://assets/Shared/Textures/Misc_Texture.png", 0.8)
	elif name.find("Advertisements") >= 0:
		node.material_override = _get_standard_mat("res://assets/Shared/Textures/Advertisements_Texture.png", 0.7)

func _apply_street_material(node: MeshInstance3D, tile_type: String, tex_dir: String) -> void:
	var base_path := tex_dir + world + "Street_Texture.png"
	var lm_path := tex_dir + tile_type + "StreetLightmap_Texture.png"
	var cache_key := tile_type + "|" + base_path
	if shader_cache.has(cache_key):
		node.material_override = shader_cache[cache_key]
		return
	var base_tex := load(base_path) as Texture2D
	var lm_tex := load(lm_path) as Texture2D
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SHADER_STREET
	mat.shader = shader
	mat.set_shader_parameter("base_tex", base_tex)
	mat.set_shader_parameter("lightmap_tex", lm_tex)
	shader_cache[cache_key] = mat
	node.material_override = mat

func _get_standard_mat(tex_path: String, roughness: float) -> StandardMaterial3D:
	if mat_cache.has(tex_path):
		return mat_cache[tex_path]
	var tex := load(tex_path) as Texture2D
	var mat := StandardMaterial3D.new()
	if tex != null:
		mat.albedo_texture = tex
	mat.roughness = roughness
	mat.metallic = 0.1
	mat_cache[tex_path] = mat
	return mat

# ---------------------------------------------------------------- AI path
func _build_ai_path() -> void:
	global_path.clear()
	path_points.clear()
	var build: Array[Dictionary] = track_data.get("build", [])
	var switch_list := {
		"SouthNorth": "NorthSouth", "NorthSouth": "SouthNorth",
		"WestEast": "EastWest", "EastWest": "WestEast",
		"SouthWest": "WestSouth", "WestSouth": "SouthWest",
		"SouthEast": "EastSouth", "EastSouth": "SouthEast",
		"WestNorth": "NorthWest", "NorthWest": "WestNorth",
		"EastNorth": "NorthEast", "NorthEast": "EastNorth",
	}
	for tile in build:
		var aipath_val: Variant = tile.get("aipath", tile.get("type", ""))
		# aipath may be an array of symbols or a single string
		var aipath: String = ""
		if aipath_val is Array and not aipath_val.is_empty():
			aipath = str(aipath_val[0])
		elif aipath_val is String:
			aipath = aipath_val
		if aipath.is_empty():
			continue
		var direction: String = tile.get("direction", "")
		var pos: Vector3 = tile.get("position", Vector3.ZERO)
		var key := aipath + "_" + direction
		var reversed := false
		var wp_list: Array = ai_paths.get(key, [])
		if wp_list.is_empty() and switch_list.has(direction):
			key = aipath + "_" + switch_list[direction]
			wp_list = ai_paths.get(key, [])
			reversed = true
		if wp_list.is_empty():
			continue
		if reversed:
			for i in range(wp_list.size() - 1, -1, -1):
				global_path.append(to_godot(pos + wp_list[i]))
		else:
			for wp in wp_list:
				global_path.append(to_godot(pos + wp))
	# deduplicate consecutive near points
	if global_path.size() > 1:
		var cleaned: Array[Vector3] = []
		cleaned.append(global_path[0])
		for i in range(1, global_path.size()):
			if global_path[i].distance_to(cleaned[-1]) > 1.0:
				cleaned.append(global_path[i])
		global_path = cleaned
	path_points = global_path

# ---------------------------------------------------------------- cars
func _spawn_cars(car_name: String) -> void:
	# player
	var pdata: Dictionary = track_data.get("player_car", {})
	var ppos := to_godot(pdata.get("position", Vector3.ZERO))
	var pori: Array = pdata.get("orientation", [0,0,0,1])
	player = Car.new()
	player.setup(car_name, 1, true, false)
	player.path = global_path
	player.primary_weapon = "MachineGun" if game_mode != "Race" and game_mode != "GooseHunt" else "NoPrimary"
	player.secondary_weapon = "RocketPod" if game_mode in ["BattleRace", "Rampage", "RivalBattle", "BossBattle", "Survivor", "Elimination"] else "NoSecondary"
	player.position = ppos
	player.heading = quat_to_yaw(pori)
	cars.append(player)
	add_child(player)
	# AI cars
	var ai_list: Array[Dictionary] = track_data.get("ai_cars", [])
	var ai_names := ["Nissan", "Eclipse", "Corvette", "Mustang", "Porsche", "AstonMartin", "AudiR8", "FordGT", "Seat"]
	var ai_idx := 0
	for adata in ai_list:
		var aname: String = str(adata.get("car", "Nissan"))
		var is_boss_car := aname.find("Boss") >= 0
		if aname == "Player":
			aname = ai_names[ai_idx % ai_names.size()]
		ai_idx += 1
		var apos := to_godot(adata.get("position", Vector3.ZERO))
		var aori: Array = adata.get("orientation", [0,0,0,1])
		var ai: Car = Car.new()
		ai.setup(aname.replace("Boss", ""), 1, false, is_boss_car)
		ai.is_ai = true
		ai.path = global_path
		ai.ai_index = 0
		# give AI weapons depending on mode
		if game_mode in ["BattleRace", "Rampage", "RivalBattle", "BossBattle", "Survivor", "Elimination"]:
			ai.primary_weapon = "MachineGun"
			ai.secondary_weapon = "RocketPod"
		ai.position = apos
		ai.heading = quat_to_yaw(aori)
		cars.append(ai)
		add_child(ai)

func _place_pickups() -> void:
	var build: Array[Dictionary] = track_data.get("build", [])
	var pickup_ps := _get_fbx("res://assets/Shared/3d/PickUps.fbx")
	if pickup_ps == null:
		return
	for tile in build:
		for key in tile.keys():
			if key.find("pickup") < 0 and key.to_lower().find("pickup") < 0:
				continue
			var list = tile[key]
			if not (list is Array):
				continue
			var model_name: String = key.replace("_PickUp", "")
			for entry in list:
				if not (entry is Dictionary):
					continue
				var pos := to_godot(entry.get("position", Vector3.ZERO))
				var node := _instantiate_model(pickup_ps, model_name, pos)
				if node != null:
					node.name = model_name
					pickups.append(node)
					add_child(node)

func _place_traffic() -> void:
	var build: Array[Dictionary] = track_data.get("build", [])
	var car_names := ["Lupo", "Truck", "Bus", "Transporter", "Nissan", "Eclipse", "Corvette", "Mustang", "Porsche"]
	for tile in build:
		for key in tile.keys():
			if key.find("_Object") >= 0 or key.find("_PickUp") >= 0:
				continue
			var list = tile[key]
			if not (list is Array):
				continue
			var car_base := ""
			for cn in car_names:
				if key.begins_with(cn):
					car_base = cn
					break
			if car_base.is_empty():
				continue
			for entry in list:
				if not (entry is Dictionary):
					continue
				var pos := to_godot(entry.get("position", Vector3.ZERO))
				var t: Car = Car.new()
				t.setup(car_base, 1, false, false)
				t.is_traffic = true
				t.is_ai = true
				t.primary_weapon = "NoPrimary"
				t.secondary_weapon = "NoSecondary"
				t.ai_speed_target = 30.0 + randf() * 10.0
				t.path = global_path
				t.ai_index = 0
				t.position = pos
				t.heading = quat_to_yaw(entry.get("orientation", [0,0,0,1]))
				var color_name: String = key.replace(car_base, "").lowercase()
				t.set_body_color(_color_for_name(color_name))
				cars.append(t)
				add_child(t)

func _color_for_name(name: String) -> Color:
	if name.find("red") >= 0:
		return Color(0.8, 0.1, 0.1)
	if name.find("blue") >= 0:
		return Color(0.1, 0.2, 0.8)
	if name.find("green") >= 0:
		return Color(0.1, 0.6, 0.2)
	if name.find("grey") >= 0 or name.find("gray") >= 0:
		return Color(0.5, 0.5, 0.5)
	if name.find("white") >= 0:
		return Color(0.9, 0.9, 0.9)
	if name.find("yellow") >= 0:
		return Color(0.9, 0.8, 0.1)
	return Color(0.7, 0.7, 0.7)

func _instantiate_model(ps: PackedScene, model_name: String, position: Vector3) -> Node3D:
	var inst := ps.instantiate()
	var found: Node3D = null
	for node in inst.get_children():
		if _clean_name(node.name) == model_name:
			found = node
			break
	if found == null:
		for node in inst.get_children():
			if _clean_name(node.name).begins_with(model_name):
				found = node
				break
	if found == null:
		return null
	var group := Node3D.new()
	found.reparent(group, true)
	group.transform.origin = position
	return group

# ---------------------------------------------------------------- camera
func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 65.0
	camera.near = 0.5
	camera.far = 2000.0
	add_child(camera)
	camera.make_current()

func _update_camera(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var back: Vector3 = -player.get_forward() * 9.0
	if cam_reversed:
		back = player.get_forward() * 9.0
	var desired: Vector3 = player.global_position + back + Vector3(0.0, 4.5, 0.0)
	camera.global_position = desired.lerp(camera.global_position, 1.0 - pow(0.001, delta))
	var look: Vector3 = player.global_position + player.get_forward() * 10.0
	camera.look_at(look, Vector3.UP)

# ---------------------------------------------------------------- HUD
func _setup_hud() -> void:
	hud = Control.new()
	hud.anchors_preset = Control.PRESET_FULL_RECT
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	layer.add_child(hud)
	var top := Label.new()
	top.text = game_mode
	top.add_theme_font_size_override("font_size", 28)
	top.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	top.position = Vector2(20, 16)
	hud.add_child(top)
	var timer_lbl := Label.new()
	timer_lbl.name = "Timer"
	timer_lbl.add_theme_font_size_override("font_size", 24)
	timer_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	timer_lbl.position = Vector2(1000, 16)
	hud.add_child(timer_lbl)
	var health_bar := ProgressBar.new()
	health_bar.name = "Health"
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.position = Vector2(20, 60)
	health_bar.size = Vector2(300, 20)
	hud.add_child(health_bar)
	var health_lbl := Label.new()
	health_lbl.text = "HP"
	health_lbl.position = Vector2(20, 44)
	hud.add_child(health_lbl)
	var nitro_bar := ProgressBar.new()
	nitro_bar.name = "Nitro"
	nitro_bar.min_value = 0.0
	nitro_bar.max_value = 1.0
	nitro_bar.value = 0.0
	nitro_bar.position = Vector2(20, 90)
	nitro_bar.size = Vector2(300, 16)
	hud.add_child(nitro_bar)
	var speed_lbl := Label.new()
	speed_lbl.name = "Speed"
	speed_lbl.add_theme_font_size_override("font_size", 22)
	speed_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	speed_lbl.position = Vector2(20, 620)
	hud.add_child(speed_lbl)
	var pos_lbl := Label.new()
	pos_lbl.name = "Pos"
	pos_lbl.add_theme_font_size_override("font_size", 22)
	pos_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	pos_lbl.position = Vector2(20, 650)
	hud.add_child(pos_lbl)
	var dmg_lbl := Label.new()
	dmg_lbl.name = "Dmg"
	dmg_lbl.add_theme_font_size_override("font_size", 18)
	dmg_lbl.position = Vector2(1000, 620)
	hud.add_child(dmg_lbl)

func _update_hud() -> void:
	if hud == null or player == null:
		return
	var t := hud.get_node_or_null("Timer") as Label
	if t:
		t.text = "%.1f" % max(0.0, target_time - timer)
	var hb := hud.get_node_or_null("Health") as ProgressBar
	if hb:
		hb.value = player.health
	var nb := hud.get_node_or_null("Nitro") as ProgressBar
	if nb:
		nb.value = player.nitro_timer / 7.5 if player.nitro_timer > 0.0 else 0.0
	var sl := hud.get_node_or_null("Speed") as Label
	if sl:
		sl.text = "%d km/h" % int(abs(player.speed) * 3.6)
	var pl := hud.get_node_or_null("Pos") as Label
	if pl:
		var pos := _get_position(player)
		pl.text = "POS: %d/%d" % [pos, cars.size()]
	var dl := hud.get_node_or_null("Dmg") as Label
	if dl:
		dl.text = "DMG: %d" % int(player.damage_dealt)

func _get_position(car: Car) -> int:
	# rank by progress along path (traffic excluded)
	var my_idx := _path_index(car.global_position)
	var rank := 1
	for c in cars:
		if c == car or c.is_traffic:
			continue
		if c.finished:
			rank += 1
		else:
			if _path_index(c.global_position) > my_idx:
				rank += 1
	return rank

func _path_index(pos: Vector3) -> int:
	var best_i := 0
	var best_d := INF
	for i in range(global_path.size()):
		var d := global_path[i].distance_to(pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

# ---------------------------------------------------------------- game loop
func _process(delta: float) -> void:
	if game_over or track_data.is_empty():
		return
	timer += delta
	# player input
	if player != null and is_instance_valid(player) and not player.finished and not player.wrecked:
		if Input.is_action_just_pressed("player_backward_cam"):
			cam_reversed = not cam_reversed
		var forward := Input.get_axis("player_backward", "player_forward")
		var left := Input.get_axis("player_right", "player_left")
		var brake := Input.is_action_pressed("player_brake")
		var nitro := Input.is_action_pressed("player_nitro")
		player.apply_input(forward, 0.0, left, 0.0, brake, nitro)
		player.apply_road_constraint(global_path, delta)
		if Input.is_action_pressed("player_action1"):
			if player.fire_primary(cars):
				AudioManager.play("machine_gun")
		if Input.is_action_pressed("player_action2"):
			if player.fire_secondary(cars, self):
				AudioManager.play("rocket")
	# update cars
	var targets := cars
	for c in cars:
		if not is_instance_valid(c):
			continue
		if c != player and c.is_ai:
			c.update_ai(delta, targets, self)
		c.update_physics(delta)
		c.update_cooldowns(delta)
		# finish check
		if not c.finished and not c.wrecked and not c.is_traffic:
			if global_path.size() > 0:
				var last := global_path[-1]
				if c.global_position.distance_to(last) < 6.0:
					c.finished = true
					c.finish_time = timer
					if c == player:
						_on_player_finish()
	# pickups
	_update_pickups(delta)
	# camera & hud
	_update_camera(delta)
	_update_hud()
	# game mode evaluation
	_evaluate_game()

func _update_pickups(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	for p in pickups:
		if not is_instance_valid(p):
			continue
		if player.global_position.distance_to(p.global_position) < 4.0:
			_apply_pickup(p)
			p.queue_free()

func _apply_pickup(p: Node3D) -> void:
	var name: String = p.name
	if name == "Nitro":
		player.nitro_timer = 7.5
		AudioManager.play("nitro")
	elif name == "Repair":
		player.health = min(player.max_health, player.health + 50.0)
		AudioManager.play("pickup_repair")
	elif name == "CashBig":
		MainManager.cash += 5000
		AudioManager.play("pickup_cash")
	elif name == "CashSmall":
		MainManager.cash += 1000
		AudioManager.play("pickup_cash")
	elif name == "HiddenPackage":
		player.damage_dealt += 0.0
		MainManager.cash += 500
		AudioManager.play("pickup")
	elif name == "Detonator":
		# damage all nearby AI
		for c in cars:
			if c != player and c.faction != player.faction and not c.wrecked:
				if c.global_position.distance_to(player.global_position) < 30.0:
					c.take_damage(100.0, player.faction)

func _evaluate_game() -> void:
	if game_over:
		return
	# time up
	if timer >= target_time:
		_end_game(false)
		return
	# mode specific
	if game_mode == "Rampage":
		if player.damage_dealt >= target_damage:
			_end_game(true)
		return
	if game_mode == "Survivor":
		var alive_ai := 0
		for c in cars:
			if c != player and c.is_ai and not c.is_traffic and not c.wrecked and not c.finished:
				alive_ai += 1
		if alive_ai == 0:
			_end_game(true)
		return
	if game_mode == "BossBattle":
		# boss is the AI with is_boss; if wrecked, win
		for c in cars:
			if c != player and c.is_boss and c.wrecked:
				_end_game(true)
				return
	# if player finished, evaluate
	if player.finished:
		_on_player_finish()

func _on_player_finish() -> void:
	if game_over:
		return
	var completed := false
	if game_mode in ["Race", "BattleRace", "GooseHunt"]:
		# player must finish first
		completed = true
		for c in cars:
			if c != player and not c.is_traffic and c.finished and c.finish_time < player.finish_time:
				completed = false
	elif game_mode == "RivalBattle":
		# win if finished before all rivals or destroyed them
		completed = true
		for c in cars:
			if c != player and c.is_ai and not c.is_traffic and not c.wrecked and c.finished and c.finish_time < player.finish_time:
				completed = false
	elif game_mode == "Elimination":
		completed = _path_index(player.global_position) >= global_path.size() * 0.5
	_end_game(completed)

func _end_game(completed: bool) -> void:
	if game_over:
		return
	game_over = true
	AudioManager.stop_music()
	AudioManager.play("result")
	var prize := 0
	if completed:
		prize = int(track_info.get("PrizeMoney", "0"))
		MainManager.cash += prize
	var result := {
		"completed": completed,
		"track": MainManager.selected_track,
		"car": MainManager.selected_car,
		"prize": prize,
		"score": int(player.damage_dealt) if player != null else 0,
		"time": timer,
	}
	# show result briefly then emit
	get_tree().create_timer(2.0).timeout.connect(func(): finished.emit(result))

# ---------------------------------------------------------------- effects
func spawn_explosion(pos: Vector3) -> void:
	if explosion_texture == null:
		return
	var ps := _get_fbx("res://assets/Shared/3d/Particles.fbx")
	if ps == null:
		return
	var inst := ps.instantiate()
	var found: Node3D = null
	for node in inst.get_children():
		if node.name.begins_with("PartExplo"):
			found = node
			break
	if found == null:
		return
	var group := Node3D.new()
	found.reparent(group, true)
	group.transform.origin = pos
	# scale up
	group.scale = Vector3(4.0, 4.0, 4.0)
	add_child(group)
	AudioManager.play("explosion")
	# fade out
	var tween := create_tween()
	tween.tween_property(group, "scale", Vector3(7.0, 7.0, 7.0), 0.3)
	tween.tween_callback(func(): group.queue_free())

# ---------------------------------------------------------------- helpers
func to_godot(v: Vector3) -> Vector3:
	# game is Z-up; Godot is Y-up
	return Vector3(v.x, v.z, -v.y)

func quat_to_yaw(ori: Array) -> float:
	if ori.size() < 4:
		return 0.0
	var x := float(ori[0])
	var y := float(ori[1])
	var z := float(ori[2])
	var w := float(ori[3])
	var q := Quaternion(x, y, z, w)
	# car forward in game frame is +Y
	var f_game: Vector3 = q.xform(Vector3(0.0, 1.0, 0.0))
	var f_godot := to_godot(f_game)
	return atan2(f_godot.x, -f_godot.z)

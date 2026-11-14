extends Node3D
## Car
## An arcade-style car with player control, AI waypoint following, health,
## weapons and nitro. Uses the original car FBX models and textures.

var model: Node3D
var wheels: Array = []
var is_player: bool = false
var is_ai: bool = false
var is_boss: bool = false
var is_traffic: bool = false
var faction: int = 0  # 0 player, 1 AI

var speed: float = 0.0
var heading: float = 0.0  # yaw around Y
var velocity: Vector3 = Vector3.ZERO

var max_speed: float = 78.0
var accel: float = 42.0
var brake: float = 70.0
var reverse_max: float = -22.0
var steer_speed: float = 2.6
var drag: float = 0.6
var grip: float = 6.0

var health: float = 100.0
var max_health: float = 100.0

var primary_weapon: String = "NoPrimary"
var secondary_weapon: String = "NoSecondary"
var primary_ammo: int = 99
var secondary_ammo: int = 99
var primary_cooldown: float = 0.0
var secondary_cooldown: float = 0.0

var nitro_timer: float = 0.0
var nitro_active: bool = false

var finished: bool = false
var finish_time: float = 0.0
var finish_position: int = 0
var lap: int = 0
var damage_dealt: float = 0.0
var kills: int = 0
var wrecked: bool = false

var path: Array[Vector3] = []  # global AI path (Vector3 list)
var ai_index: int = 0
var ai_speed_target: float = 55.0
var ai_aggro: float = 0.5
var ai_weapon_cooldown: float = 0.0
var car_name: String = ""

signal wrecked_signal()

func _ready() -> void:
	pass

func setup(car_name: String, skin_index: int, is_plr: bool, is_boss_car: bool) -> void:
	self.car_name = car_name
	is_player = is_plr
	is_boss = is_boss_car
	faction = 0 if is_plr else 1
	max_health = 100.0 if not is_boss else 200.0
	health = max_health
	if is_ai:
		ai_speed_target = 52.0 + randf() * 8.0
	model = create_car_model(car_name, skin_index)
	add_child(model)

func create_car_model(car_name: String, skin_index: int) -> Node3D:
	var root := Node3D.new()
	var fbx_path := "res://assets/Cars/3d/" + car_name + ".fbx"
	var ps := load(fbx_path) as PackedScene
	if ps == null:
		push_error("Car: cannot load FBX " + fbx_path)
		return root
	var inst := ps.instantiate()
	root.add_child(inst)
	var skin_tex := load("res://assets/Cars/SkinTextures/" + car_name + "Skin" + str(skin_index) + "_Texture.png")
	var wheels_tex := load("res://assets/Cars/SkinTextures/Wheels_Texture.png")
	var front_tex := load("res://assets/Cars/SkinTextures/FrontLight_Texture.png")
	var rear_tex := load("res://assets/Cars/SkinTextures/RearLight_Texture.png")
	for node in inst.get_children():
		if node is MeshInstance3D:
			var mesh: ArrayMesh = node.mesh
			if mesh == null:
				continue
			var name: String = node.name
			var mat := StandardMaterial3D.new()
			if name.find("Wheel") >= 0:
				mat.albedo_texture = wheels_tex
				mat.roughness = 0.8
			elif name.find("FrontLight") >= 0:
				mat.albedo_texture = front_tex
				mat.emission_enabled = true
				mat.emission = Color(1, 1, 0.8)
				mat.emission_energy_multiplier = 2.0
			elif name.find("RearLight") >= 0:
				mat.albedo_texture = rear_tex
				mat.emission_enabled = true
				mat.emission = Color(1, 0, 0)
				mat.emission_energy_multiplier = 1.5
			else:
				mat.albedo_texture = skin_tex
				mat.roughness = 0.45
				mat.metallic = 0.2
			node.material_override = mat
			if name.find("Wheel") >= 0:
				wheels.append(node)
	return root

func set_body_color(color: Color) -> void:
	if model == null:
		return
	for node in model.get_children():
		_tint_node(node, color)

func _tint_node(node: Node, color: Color) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var m := child.material_override as StandardMaterial3D
			var name := _clean_mesh_name(child.name)
			# tint body, glass, lights; skip wheels/rims to keep tyres dark
			if name.find("Wheel") < 0 and name.find("Rim") < 0:
				m.albedo_color = color
			if child.get_children().size() > 0:
				_tint_node(child, color)

func _clean_mesh_name(name: String) -> String:
	if name.begins_with("Model::"):
		return name.substr(7)
	return name

func apply_input(forward: float, back: float, left: float, right: float, brake: bool, nitro: bool) -> void:
	if finished or wrecked:
		return
	# acceleration
	if forward > 0.0:
		speed += accel * forward * get_process_delta_time()
	elif back > 0.0:
		speed -= accel * back * get_process_delta_time()
	# braking / reverse
	if brake:
		if speed > 0.0:
			speed = max(0.0, speed - self.brake * get_process_delta_time())
		else:
			speed = max(reverse_max, speed - self.brake * get_process_delta_time())
	# nitro
	if nitro and nitro_timer > 0.0:
		nitro_active = true
	else:
		nitro_active = false
	# steering (scaled by speed)
	var steer := (left - right) * steer_speed
	heading += steer * get_process_delta_time() * (0.4 + clamp(abs(speed) / max_speed, 0.0, 1.0))
	# clamp speed
	var max_s := max_speed * (1.5 if nitro_active else 1.0)
	speed = clamp(speed, reverse_max, max_s)
	# drag
	speed *= max(0.0, 1.0 - drag * get_process_delta_time())

func update_physics(delta: float) -> void:
	if finished or wrecked:
		speed *= max(0.0, 1.0 - 4.0 * delta)
		velocity = Vector3.ZERO
		return
	# forward vector (car forward is -Z in local space)
	var forward_vec := Vector3(0.0, 0.0, -1.0).rotated(Vector3(0.0, 1.0, 0.0), heading)
	# apply movement
	var move := forward_vec * speed * delta
	global_position += move
	# keep on ground
	global_position.y = 0.0
	# wheel spin and steer visuals
	for w in wheels:
		if is_instance_valid(w):
			w.rotation.y += speed * delta * 0.5
	# nitro timer
	if nitro_timer > 0.0:
		nitro_timer -= delta
		if nitro_timer <= 0.0:
			nitro_timer = 0.0
			nitro_active = false
	# health regen? no. wrecked check
	if health <= 0.0 and not wrecked:
		wrecked = true
		wrecked_signal.emit()

func get_forward() -> Vector3:
	return Vector3(0.0, 0.0, -1.0).rotated(Vector3(0.0, 1.0, 0.0), heading)

func get_right() -> Vector3:
	return Vector3(1.0, 0.0, 0.0).rotated(Vector3(0.0, 1.0, 0.0), heading)

func apply_road_constraint(path: Array[Vector3], delta: float) -> void:
	if path.is_empty() or finished or wrecked:
		return
	var pos := global_position
	var best_i := 0
	var best_d := INF
	for i in range(path.size()):
		var d := path[i].distance_to(pos)
		if d < best_d:
			best_d = d
			best_i = i
	var p := path[best_i]
	var dir := Vector3.ZERO
	if best_i + 1 < path.size():
		dir = (path[best_i + 1] - p).normalized()
	elif best_i > 0:
		dir = (p - path[best_i - 1]).normalized()
	var to_path := p - pos
	var lateral := to_path - dir * to_path.dot(dir)
	var lateral_len := lateral.length()
	if lateral_len > 1.2:
		var correction := -lateral.normalized() * min(lateral_len * 4.0, 40.0) * delta
		global_position += correction
	if lateral_len > 0.4:
		var desired := atan2(dir.x, -dir.z)
		var diff := wrapf(desired - heading, -PI, PI)
		heading += clamp(diff, -2.5 * delta, 2.5 * delta)

func take_damage(amount: float, from_faction: int) -> void:
	if finished or wrecked:
		return
	if from_faction == faction:
		return
	health -= amount
	if health <= 0.0:
		health = 0.0

func fire_primary(targets: Array[Car]) -> bool:
	if primary_weapon == "NoPrimary" or primary_ammo <= 0 or primary_cooldown > 0.0 or finished or wrecked:
		return false
	var data: Dictionary = GameData.weapons.get(primary_weapon, {})
	var rof: float = float(data.get("rof", 8))
	primary_cooldown = 1.0 / rof
	primary_ammo -= 1
	# hitscan: find nearest target in front
	var fwd := get_forward()
	var best: Car = null
	var best_dist := 200.0
	for t in targets:
		if t is Car and not t.wrecked and t.faction != faction:
			var to := t.global_position - global_position
			var dist := to.length()
			if dist < best_dist:
				var dot := to.normalized().dot(fwd)
				if dot > 0.3:
					best = t
					best_dist = dist
	if best != null:
		var dmg := randf_range(float(data.get("damage", [1, 3])[0]), float(data.get("damage", [1, 3])[1]))
		best.take_damage(dmg, faction)
		damage_dealt += dmg
	return true

func fire_secondary(targets: Array[Car], race: Node) -> bool:
	if secondary_weapon == "NoSecondary" or secondary_ammo <= 0 or secondary_cooldown > 0.0 or finished or wrecked:
		return false
	var data: Dictionary = GameData.weapons.get(secondary_weapon, {})
	var rof: float = float(data.get("rof", 1))
	secondary_cooldown = 1.0 / rof
	secondary_ammo -= 1
	# area damage: damage all targets within range in front
	var fwd := get_forward()
	var range := 60.0
	var dmg_min := float(data.get("damage", [20, 40])[0])
	var dmg_max := float(data.get("damage", [20, 40])[1])
	for t in targets:
		if t is Car and not t.wrecked and t.faction != faction:
			var to := t.global_position - global_position
			var dist := to.length()
			if dist < range and to.normalized().dot(fwd) > 0.0:
				var dmg := randf_range(dmg_min, dmg_max)
				t.take_damage(dmg, faction)
				damage_dealt += dmg
	# spawn explosion effect
	if race != null and race.has_method("spawn_explosion"):
		race.spawn_explosion(global_position + fwd * 10.0)
	return true

func update_ai(delta: float, targets: Array[Car], race: Node) -> void:
	if finished or wrecked or path.is_empty():
		return
	# find next waypoint
	var target := path[ai_index]
	var to := target - global_position
	var dist := to.length()
	if dist < 6.0:
		ai_index = (ai_index + 1) % path.size()
		target = path[ai_index]
		to = target - global_position
		dist = to.length()
	# steer toward target
	var desired_heading := atan2(to.x, -to.z)
	var diff := wrapf(desired_heading - heading, -PI, PI)
	heading += clamp(diff, -steer_speed * delta, steer_speed * delta)
	# speed control
	var target_speed := ai_speed_target
	if abs(diff) > 1.2:
		target_speed *= 0.5
	if speed < target_speed:
		speed += accel * 0.8 * delta
	else:
		speed -= brake * 0.5 * delta
	speed = clamp(speed, 0.0, max_speed)
	# weapons
	ai_weapon_cooldown -= delta
	if ai_weapon_cooldown <= 0.0 and targets.size() > 0:
		# find nearest enemy
		var best: Car = null
		var best_d := 120.0
		for t in targets:
			if t is Car and not t.wrecked and t.faction != faction:
				var d := t.global_position.distance_to(global_position)
				if d < best_d:
					best = t
					best_d = d
			if best != null and best_d < 80.0:
				# align facing
				var to_best := best.global_position - global_position
				var desired := atan2(to_best.x, -to_best.z)
				if abs(wrapf(desired - heading, -PI, PI)) < 0.5:
					if primary_weapon != "NoPrimary" and primary_ammo > 0:
						fire_primary(targets)
					if secondary_weapon != "NoSecondary" and secondary_ammo > 0 and randf() < 0.3:
						fire_secondary(targets, race)
					ai_weapon_cooldown = 1.5

func update_cooldowns(delta: float) -> void:
	if primary_cooldown > 0.0:
		primary_cooldown -= delta
	if secondary_cooldown > 0.0:
		secondary_cooldown -= delta

func wrapf(v: float, lo: float, hi: float) -> float:
	while v < lo:
		v += (hi - lo)
	while v >= hi:
		v -= (hi - lo)
	return v

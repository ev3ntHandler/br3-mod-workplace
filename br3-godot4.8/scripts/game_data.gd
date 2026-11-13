extends Node
## GameData
## Singleton that parses the original Burnin' Rubber 3 data files (txt) into
## usable dictionaries. All data is read from the original assets folder.

const DATA_ROOT := "res://assets/"

var globals: Dictionary = {}
var texts: Dictionary = {}
var track_info: Array = []
var cars: Dictionary = {}
var personalities: Dictionary = {}
var weapons: Dictionary = {}
var upgrades: Dictionary = {}
var bodykits: Dictionary = {}
var physics_objects: Dictionary = {}
var particles: Dictionary = {}
var rewards: Dictionary = {}
var triggers: Dictionary = {}
var track_index: Dictionary = {}  # track name -> info dict

func _ready() -> void:
	load_all()

func load_all() -> void:
	load_globals()
	load_texts()
	load_track_info()
	load_cars()
	load_shared()

# ---------------------------------------------------------------- globals
func load_globals() -> void:
	var f := FileAccess.open(DATA_ROOT + "Globals.txt", FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open Globals.txt")
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("//"):
			continue
		var parts := line.split("\t")
		if parts.size() >= 2:
			globals[parts[0].strip_edges()] = parse_value(parts[1].strip_edges())

# ---------------------------------------------------------------- texts (MenuData.txt)
func load_texts() -> void:
	var f := FileAccess.open(DATA_ROOT + "Menu/MenuData.txt", FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open MenuData.txt")
		return
	var section := ""
	while not f.eof_reached():
		var raw := f.get_line()
		var line := raw.strip_edges()
		if line.is_empty():
			continue
		if line.ends_with("_Begin"):
			section = line.replace("_Begin", "")
			continue
		if line.ends_with("_End"):
			section = ""
			continue
		if section == "Text":
			var parts := line.split("\t")
			if parts.size() >= 2:
				texts[parts[0].strip_edges()] = parts[1].strip_edges()
		elif section == "TextColor":
			var parts := line.split("\t")
			if parts.size() >= 2:
				texts["color_" + parts[0].strip_edges()] = parts[1].strip_edges()

# ---------------------------------------------------------------- track info
func load_track_info() -> void:
	var f := FileAccess.open(DATA_ROOT + "Menu/TrackInfo.txt", FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open TrackInfo.txt")
		return
	var header := f.get_line().strip_edges().split("\t")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("\t")
		if parts.size() < header.size():
			continue
		var d := {}
		for i in range(header.size()):
			d[header[i]] = parts[i].strip_edges()
		track_info.append(d)
		track_index[d["TrackName"]] = d

# ---------------------------------------------------------------- cars
func load_cars() -> void:
	var f := FileAccess.open(DATA_ROOT + "Cars/CarsData.txt", FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open CarsData.txt")
		return
	var section := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.ends_with("_Begin"):
			section = line.replace("_Begin", "")
			continue
		if line.ends_with("_End"):
			section = ""
			continue
		if section == "Cars":
			var parts := line.split("\t")
			if parts.size() >= 2 and not parts[0].begins_with("//"):
				cars[parts[0].strip_edges()] = parse_proplist(parts[1])
		elif section == "Personality":
			var parts := line.split("\t")
			if parts.size() >= 2 and not parts[0].begins_with("//"):
				personalities[parts[0].strip_edges()] = parse_proplist(parts[1])

# ---------------------------------------------------------------- shared data
func load_shared() -> void:
	var f := FileAccess.open(DATA_ROOT + "Shared/SharedData.txt", FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open SharedData.txt")
		return
	var section := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.ends_with("_Begin"):
			section = line.replace("_Begin", "")
			continue
		if line.ends_with("_End"):
			section = ""
			continue
		if line.begins_with("//"):
			continue
		var parts := line.split("\t")
		if parts.size() < 2:
			continue
		var key := parts[0].strip_edges()
		var val := parts[1].strip_edges()
		if section == "PrimaryWeapons":
			weapons[key] = parse_proplist(val)
		elif section == "SecondaryWeapons":
			weapons[key] = parse_proplist(val)
		elif section == "CarUpgrades":
			upgrades[key] = parse_proplist(val)
		elif section == "CarBodyKits":
			bodykits[key] = parse_proplist(val)
		elif section == "PhysicsObjects":
			physics_objects[key] = parse_proplist(val)
		elif section == "Particles":
			particles[key] = parse_proplist(val)
		elif section == "Rewards":
			rewards[key] = val
		elif section == "Triggers":
			triggers[key] = val

# ---------------------------------------------------------------- parsing helpers
func parse_value(s: String) -> Variant:
	s = s.strip_edges()
	if s.begins_with("[") and s.ends_with("]"):
		return parse_list(s)
	if s.begins_with("vector(") and s.ends_with(")"):
		return parse_vector(s)
	if s.begins_with("\"") and s.ends_with("\""):
		return s.replace("\"", "")
	if s == "TRUE":
		return true
	if s == "FALSE":
		return false
	if s == "#none":
		return null
	if s.is_valid_float():
		return s.to_float()
	if s.is_valid_int():
		return s.to_int()
	return s

func parse_list(s: String) -> Array:
	var inner := s.trim_prefix("[").trim_suffix("]")
	var arr := []
	var depth := 0
	var cur := ""
	var in_str := false
	for ch in inner:
		if ch == "\"":
			in_str = not in_str
			cur += ch
		elif not in_str:
			if ch == "[":
				depth += 1
				cur += ch
			elif ch == "]":
				depth -= 1
				cur += ch
			elif ch == "," and depth == 0:
				arr.append(parse_value(cur))
				cur = ""
			else:
				cur += ch
		else:
			cur += ch
	if not cur.is_empty():
		arr.append(parse_value(cur))
	return arr

func parse_vector(s: String) -> Vector3:
	s = s.strip_edges()
	# handle "vector (x,y,z)" or "vector(x,y,z)"
	var vidx := s.find("vector")
	if vidx >= 0:
		s = s.substr(vidx + 6)
	var op := s.find("(")
	var cp := s.rfind(")")
	if op >= 0 and cp > op:
		s = s.substr(op + 1, cp - op - 1)
	var parts := s.split(",")
	if parts.size() >= 3:
		return Vector3(parts[0].strip_edges().to_float(),
			parts[1].strip_edges().to_float(),
			parts[2].strip_edges().to_float())
	return Vector3.ZERO

func split_top_level(s: String) -> Array:
	# Split on commas at bracket/paren depth 0, respecting quotes.
	var arr := []
	var depth := 0
	var in_str := false
	var cur := ""
	for ch in s:
		if ch == "\"":
			in_str = not in_str
			cur += ch
		elif not in_str:
			if ch == "[" or ch == "(" or ch == "{":
				depth += 1
				cur += ch
			elif ch == "]" or ch == ")" or ch == "}":
				depth -= 1
				cur += ch
			elif ch == "," and depth == 0:
				arr.append(cur)
				cur = ""
			else:
				cur += ch
		else:
			cur += ch
	if not cur.is_empty():
		arr.append(cur)
	return arr

func parse_proplist(s: String) -> Dictionary:
	var d := {}
	s = s.strip_edges()
	if not (s.begins_with("[") and s.ends_with("]")):
		return d
	var inner := s.trim_prefix("[").trim_suffix("]")
	var depth := 0
	var in_str := false
	var cur := ""
	var sep := false
	for ch in inner:
		if ch == "\"":
			in_str = not in_str
			cur += ch
		elif not in_str:
			if ch == "[":
				depth += 1
				cur += ch
			elif ch == "]":
				depth -= 1
				cur += ch
			elif ch == "," and depth == 0:
				add_prop(d, cur)
				cur = ""
				sep = true
			else:
				cur += ch
		else:
			cur += ch
	if not cur.is_empty():
		add_prop(d, cur)
	return d

func add_prop(d: Dictionary, raw: String) -> void:
	var p := raw.strip_edges()
	if p.is_empty():
		return
	# key: value  (key may be #symbol or plain)
	var idx := p.find(":")
	if idx < 0:
		return
	var key := p.substr(0, idx).strip_edges().lstrip("#")
	var val := p.substr(idx + 1).strip_edges()
	d[key] = parse_value(val)

# ---------------------------------------------------------------- track events
func load_track_events(world: String, track: String) -> Dictionary:
	# world e.g. "City", track e.g. "1"
	var path := DATA_ROOT + "Tracks/" + world + "/Data/" + world + "Track" + track + "Events.txt"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open track events: " + path)
		return {}
	var data := {}
	var build: Array = []
	var in_data := false
	var in_build := false
	var data_key := ""
	while not f.eof_reached():
		var line := f.get_line()
		var s := line.strip_edges()
		if s.ends_with("Data_Begin"):
			in_data = true
			continue
		if s.ends_with("Data_End"):
			in_data = false
			continue
		if s.ends_with("Build_Begin"):
			in_build = true
			continue
		if s.ends_with("Build_End"):
			in_build = false
			continue
		if in_data and not s.is_empty():
			var parts := line.split("\t")
			if parts.size() >= 2:
				var k := parts[0].strip_edges()
				var v := parts[1].strip_edges()
				if k == "PlayerCar":
					data["player_car"] = parse_proplist(v)
				elif k == "AICar":
					if not data.has("ai_cars"):
						data["ai_cars"] = []
					data["ai_cars"].append(parse_proplist(v))
				else:
					data[k] = parse_value(v)
		if in_build and s.begins_with("CreateTile"):
			build.append(parse_create_tile(line))
	data["build"] = build
	return data

func parse_create_tile(line: String) -> Dictionary:
	var d := {}
	# type
	var mt := line.find("#type:")
	if mt >= 0:
		var rest := line.substr(mt + 6)
		var q1 := rest.find("\"")
		var q2 := rest.find("\"", q1 + 1)
		if q1 >= 0 and q2 >= 0:
			d["type"] = rest.substr(q1 + 1, q2 - q1 - 1)
	# direction
	var md := line.find("#direction:")
	if md >= 0:
		var rest := line.substr(md + 11)
		var q1 := rest.find("\"")
		var q2 := rest.find("\"", q1 + 1)
		if q1 >= 0 and q2 >= 0:
			d["direction"] = rest.substr(q1 + 1, q2 - q1 - 1)
	# aipath
	var ma := line.find("#aipath:")
	if ma >= 0:
		var rest := line.substr(ma + 8)
		var q1 := rest.find("\"")
		var q2 := rest.find("\"", q1 + 1)
		if q1 >= 0 and q2 >= 0:
			d["aipath"] = rest.substr(q1 + 1, q2 - q1 - 1)
	# position
	var mp := line.find("#position:")
	if mp >= 0:
		var rest := line.substr(mp + 10)
		d["position"] = parse_vector(rest)
	# deco
	var mde := line.find("#deco:")
	if mde >= 0:
		var rest := line.substr(mde + 6)
		d["deco"] = rest.strip_edges().to_int()
	# parent
	var mpar := line.find("#parent:")
	if mpar >= 0:
		var rest := line.substr(mpar + 8)
		d["parent"] = rest.strip_edges().to_int()
	# remaining props: objects, pickups, traffic
	# Collect all "#key: value" pairs after type/direction/aipath/position/deco/parent
	var m := line.find("[")
	if m >= 0:
		var inner := line.substr(m + 1)
		# split by ',' at depth 0 respecting brackets/quotes
		var parts := split_props(inner)
		for p in parts:
			var key := ""
			var val := ""
			var idx := p.find(":")
			if idx >= 0:
				key = p.substr(0, idx).strip_edges().lstrip("#")
				val = p.substr(idx + 1).strip_edges()
			if key in ["type", "direction", "aipath", "position", "deco", "parent"]:
				continue
			d[key] = parse_tile_value(val)
	return d

func split_props(s: String) -> Array:
	return split_top_level(s)

func parse_tile_value(s: String) -> Variant:
	s = s.strip_edges()
	if s.begins_with("[[") and s.ends_with("]]"):
		# list of [vector, quaternion] pairs
		return parse_object_list(s)
	if s.begins_with("[") and s.ends_with("]"):
		return parse_list(s)
	if s.begins_with("vector("):
		return parse_vector(s)
	return s

func parse_object_list(s: String) -> Array:
	# [[vector(...), [x,y,z,w]], [vector(...), [x,y,z,w]]]
	s = s.strip_edges()
	# strip one outer list bracket: [ [obj], [obj] ] -> [obj], [obj]
	var inner := s.trim_prefix("[").trim_suffix("]")
	var arr := []
	for part in split_top_level(inner):
		arr.append(parse_object_pair(part))
	return arr

func parse_object_pair(s: String) -> Dictionary:
	var d := {}
	s = s.strip_edges()
	# strip surrounding pair brackets if present
	if s.begins_with("[") and s.ends_with("]"):
		s = s.trim_prefix("[").trim_suffix("]")
	# vector(...) first
	var vm := s.find("vector")
	var after_vec := s
	if vm >= 0:
		var op := s.find("(", vm)
		var cp := s.rfind(")", vm)
		if op >= 0 and cp > op:
			d["position"] = parse_vector(s.substr(vm, cp - vm + 1))
		after_vec = s.substr(cp + 1)
	# remaining [x,y,z,w] quaternion
	var qm := after_vec.find("[")
	if qm >= 0:
		var qend := after_vec.rfind("]")
		if qend > qm:
			d["orientation"] = parse_list(after_vec.substr(qm, qend - qm + 1))
	return d

# ---------------------------------------------------------------- AI paths
func load_ai_paths(world: String) -> Dictionary:
	var path := DATA_ROOT + "Tracks/" + world + "/Data/" + world + "Data.txt"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: cannot open AI paths: " + path)
		return {}
	var paths := {}
	var in_paths := false
	while not f.eof_reached():
		var line := f.get_line()
		var s := line.strip_edges()
		if s.ends_with("AIPaths_Begin"):
			in_paths = true
			continue
		if s.ends_with("AIPaths_End"):
			in_paths = false
			continue
		if in_paths and not s.is_empty():
			var parts := line.split("\t")
			if parts.size() >= 2:
				var name := parts[0].strip_edges()
				var val := parts[1].strip_edges()
				paths[name] = parse_ai_path(val)
	return paths

func parse_ai_path(s: String) -> Array:
	s = s.strip_edges()
	var inner := s.trim_prefix("[").trim_suffix("]")
	var arr := []
	for part in split_top_level(inner):
		arr.append(parse_vector(part))
	return arr

# ---------------------------------------------------------------- helpers
func get_text(key: String, default: String = "") -> String:
	if texts.has(key):
		return texts[key]
	return default

func get_track(name: String) -> Dictionary:
	if track_index.has(name):
		return track_index[name]
	return {}

func list_tracks() -> Array:
	return track_info.duplicate()

func get_available_cars() -> Array:
	if globals.has("AvailableCars") and globals["AvailableCars"] is Array:
		return globals["AvailableCars"]
	return []

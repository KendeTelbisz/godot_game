extends RefCounted

const SAVE_PATH := "user://player_data.json"

static var _data := {}


static func _defaults() -> Dictionary:
	return {
		"points": 0,
		"deaths": 0,
		"shop": {
			"speed": 0,
			"jump": 0,
			"magnet_force": 0,
			"magnet_speed": 0
		},
		"player": {
			"speed": 700.0,
			"acceleration": 6000.0,
			"air_acceleration": 4000.0,
			"friction": 9000.0,
			"jump_velocity": -1100.0,
			"gravity": 2000.0,
			"max_fall_speed": 2200.0,
			"magnetic_strength_multiplier": 8000000000.0,
			"min_distance": 80.0,
			"max_magnetic_force": 20000.0,
			"magnetic_damping": 2.0,
			"max_magnetic_speed": 2500.0,
			"magnet_contact_tolerance": 24.0
		}
	}


static func reload() -> void:
	_data = _load()


static func data() -> Dictionary:
	if _data.is_empty():
		_data = _load()
	return _data


static func _load() -> Dictionary:
	var result := _defaults()
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for key in parsed:
					if key == "player" and parsed[key] is Dictionary:
						for stat in parsed[key]:
							result["player"][stat] = parsed[key][stat]
					else:
						result[key] = parsed[key]
	_write(result)
	return result


static func _write(value: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(value, "\t"))


static func save() -> void:
	_write(data())


static func get_points() -> int:
	return int(data().get("points", 0))


static func add_points(amount: int) -> void:
	data()["points"] = get_points() + amount
	save()


static func reset_points() -> void:
	data()["points"] = 0
	data()["deaths"] = int(data().get("deaths", 0)) + 1
	save()


static func spend_points(amount: int) -> bool:
	if amount <= 0 or amount > get_points():
		return false
	data()["points"] = get_points() - amount
	save()
	return true


static func get_shop_level(id: String) -> int:
	var shop: Dictionary = data().get("shop", {})
	return int(shop.get(id, 0))


static func add_shop_level(id: String) -> void:
	var shop: Dictionary = data().get("shop", {})
	shop[id] = int(shop.get(id, 0)) + 1
	data()["shop"] = shop
	save()


static func add_player_stat(key: String, amount: float) -> void:
	var stats: Dictionary = data().get("player", {})
	stats[key] = float(stats.get(key, 0.0)) + amount
	data()["player"] = stats
	save()


static func apply_player_stats(player: Node) -> void:
	var stats: Dictionary = data().get("player", {})
	for key in stats:
		if player.get(key) != null:
			player.set(key, stats[key])

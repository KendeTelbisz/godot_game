extends Node2D

const GameData := preload("res://scripts/game_data.gd")
const POINT_SCENE := preload("res://scenes/point.tscn")
const MAGNET_SCENE := preload("res://scenes/magnet.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const MAIN_MENU := "res://scenes/MainMenu.tscn"
const TEX_NORTH := preload("res://assets/object-POS.svg")
const TEX_SOUTH := preload("res://assets/object-NEG.svg")
const POINTS_PER_MAGNET := 4
const MAGNET_COUNT := 8
const TOTAL_POINTS := MAGNET_COUNT * POINTS_PER_MAGNET
const LEASH_DISTANCE := 3800.0
const LEASH_TIME := 1.0
const SPAWN_HAZARD_CLEARANCE := 450.0
const POINT_HAZARD_CLEARANCE := 250.0

const MAGNET_POSITIONS := [
	Vector2(700, 300),
	Vector2(2300, 700),
	Vector2(3900, 900),
	Vector2(5200, -500),
	Vector2(4600, -2200),
	Vector2(3000, -3300),
	Vector2(1300, -2400),
	Vector2(2500, -1300),
]

const HAZARD_POSITIONS := [
	Vector2(1500, -800),
	Vector2(3300, 0),
	Vector2(4500, -1300),
	Vector2(3900, -2950),
	Vector2(2000, -3000),
]

@onready var label: Label = $HUD/PointsLabel
@onready var player: CharacterBody2D = $CharacterBody2D

var remaining := TOTAL_POINTS
var leash_time := 0.0
var dying := false


func _ready() -> void:
	GameData.reload()
	GameData.apply_player_stats(player)
	var magnets := _create_magnets()
	_randomize_magnets(magnets)
	_spawn_hazards()
	_place_player(magnets)
	_spawn_points(magnets)
	_update_label()


func _create_magnets() -> Array:
	var result: Array = []
	for position in MAGNET_POSITIONS:
		var magnet := MAGNET_SCENE.instantiate()
		add_child(magnet)
		magnet.global_position = position
		result.append(magnet)
	return result


func _randomize_magnets(magnets: Array) -> void:
	var first_polarity := randi() % 2
	for i in magnets.size():
		var polarity := (first_polarity + i) % 2
		var magnet: Area2D = magnets[i]
		magnet.polarity = polarity
		var sprite: Sprite2D = magnet.get_node("Sprite2D")
		sprite.texture = TEX_NORTH if polarity == 0 else TEX_SOUTH


func _spawn_hazards() -> void:
	for position in HAZARD_POSITIONS:
		var hazard := HAZARD_SCENE.instantiate()
		add_child(hazard)
		hazard.global_position = position
		hazard.hit.connect(_on_player_died)


func _spawn_points(magnets: Array) -> void:
	for i in TOTAL_POINTS:
		var magnet: Area2D = magnets[i % magnets.size()]
		var distance := _orbit_distance(magnet) + randf_range(-80.0, 150.0)
		var angle := _safe_angle(magnet, distance)
		var point := POINT_SCENE.instantiate()
		add_child(point)
		point.global_position = magnet.global_position + Vector2.RIGHT.rotated(angle) * distance
		point.collected.connect(_on_point_collected)


func _safe_angle(magnet: Area2D, distance: float) -> float:
	for attempt in 32:
		var angle := randf() * TAU
		var position := magnet.global_position + Vector2.RIGHT.rotated(angle) * distance
		if player.global_position.distance_to(position) > 300.0 and _hazards_clear(position, POINT_HAZARD_CLEARANCE):
			return angle
	return randf() * TAU


func _place_player(magnets: Array) -> void:
	var chosen: Area2D = magnets.pick_random()
	var distance := _orbit_distance(chosen) + randf_range(200.0, 500.0)
	var angle := randf() * TAU
	for attempt in 64:
		var position := chosen.global_position + Vector2.RIGHT.rotated(angle) * distance
		if _hazards_clear(position, SPAWN_HAZARD_CLEARANCE):
			break
		chosen = magnets.pick_random()
		distance = _orbit_distance(chosen) + randf_range(200.0, 500.0)
		angle = randf() * TAU
	player.global_position = chosen.global_position + Vector2.RIGHT.rotated(angle) * distance
	player.velocity = Vector2.ZERO
	player.current_polarity = 1 - int(chosen.polarity)


func _hazards_clear(position: Vector2, radius: float) -> bool:
	for hazard in get_tree().get_nodes_in_group("hazards"):
		if position.distance_to(hazard.global_position) < radius:
			return false
	return true


func _physics_process(delta: float) -> void:
	if remaining <= 0 or dying:
		return
	var magnets := get_tree().get_nodes_in_group("magnets")
	if magnets.is_empty():
		return
	var nearest := _nearest_magnet(magnets)
	if player.global_position.distance_to(nearest.global_position) > LEASH_DISTANCE:
		leash_time += delta
		if leash_time >= LEASH_TIME:
			leash_time = 0.0
			_place_player(magnets)
	else:
		leash_time = 0.0


func _nearest_magnet(magnets: Array) -> Area2D:
	var nearest: Area2D = magnets[0]
	for magnet in magnets:
		if player.global_position.distance_to(magnet.global_position) < player.global_position.distance_to(nearest.global_position):
			nearest = magnet
	return nearest


func _orbit_distance(magnet: Area2D) -> float:
	return _circle_radius(magnet) + _circle_radius(player)


func _circle_radius(node: Node) -> float:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape.radius
	return 0.0


func _on_point_collected() -> void:
	if dying:
		return
	remaining -= 1
	GameData.add_points(1)
	_update_label()
	if remaining <= 0:
		_finish()


func _on_player_died() -> void:
	if dying:
		return
	dying = true
	GameData.reset_points()
	await get_tree().create_timer(0.4).timeout
	get_tree().reload_current_scene()


func _update_label() -> void:
	label.text = "Pont: %d / %d" % [TOTAL_POINTS - remaining, TOTAL_POINTS]


func _finish() -> void:
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file(MAIN_MENU)

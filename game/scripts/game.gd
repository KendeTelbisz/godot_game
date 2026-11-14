extends Node2D

const POINT_SCENE := preload("res://scenes/point.tscn")
const MAIN_MENU := "res://scenes/MainMenu.tscn"
const TOTAL_POINTS := 6
const TEX_NORTH := preload("res://assets/object-POS.svg")
const TEX_SOUTH := preload("res://assets/object-NEG.svg")
const LEASH_DISTANCE := 3800.0
const LEASH_TIME := 1.0

@onready var label: Label = $HUD/PointsLabel
@onready var player: CharacterBody2D = $CharacterBody2D

var remaining := TOTAL_POINTS
var leash_time := 0.0


func _ready() -> void:
	var magnets := get_tree().get_nodes_in_group("magnets")
	if magnets.is_empty():
		return

	_randomize_magnets(magnets)
	_place_player(magnets)
	_spawn_points(magnets)
	_update_label()


func _randomize_magnets(magnets: Array) -> void:
	var first_polarity := randi() % 2
	for i in magnets.size():
		var polarity := (first_polarity + i) % 2
		var magnet: Area2D = magnets[i]
		magnet.polarity = polarity
		var sprite: Sprite2D = magnet.get_node("Sprite2D")
		sprite.texture = TEX_NORTH if polarity == 0 else TEX_SOUTH


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
		if player.global_position.distance_to(position) > 300.0:
			return angle
	return randf() * TAU


func _place_player(magnets: Array) -> void:
	var magnet: Area2D = magnets.pick_random()
	var distance := _orbit_distance(magnet) + randf_range(200.0, 500.0)
	var angle := randf() * TAU
	player.global_position = magnet.global_position + Vector2.RIGHT.rotated(angle) * distance
	player.velocity = Vector2.ZERO
	player.current_polarity = 1 - int(magnet.polarity)


func _physics_process(delta: float) -> void:
	if remaining <= 0:
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
	remaining -= 1
	_update_label()
	if remaining <= 0:
		_finish()


func _update_label() -> void:
	label.text = "Pont: %d / %d" % [TOTAL_POINTS - remaining, TOTAL_POINTS]


func _finish() -> void:
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file(MAIN_MENU)

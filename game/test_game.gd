extends SceneTree

var game: Node
var player: CharacterBody2D
var label: Label
var magnets: Array = []
var nearest: Node2D
var other: Node2D
var failures: Array = []
var phase := 0
var phase_frame := 0


func _initialize() -> void:
	game = load("res://scenes/node_2d.tscn").instantiate()
	root.add_child(game)
	current_scene = game


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		print("FAIL: ", message)


func _point_nodes() -> Array:
	var result: Array = []
	for child in game.get_children():
		if child.scene_file_path == "res://scenes/point.tscn":
			result.append(child)
	return result


func _first_circle_radius(node: Node) -> float:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape.radius
	return 0.0


func _contact_distance(magnet: Node) -> float:
	return _first_circle_radius(magnet) + _first_circle_radius(player)


func _attached_to(magnet: Node) -> bool:
	var distance: float = player.global_position.distance_to(magnet.global_position)
	return distance <= _contact_distance(magnet) + 24.0


func _finish(result: bool) -> void:
	print("RESULT: ", "ALL TESTS PASSED" if result else "%d FAILURE(S): %s" % [failures.size(), ", ".join(failures)])
	quit(0 if result else 1)


func _physics_process(_delta: float) -> bool:
	phase_frame += 1

	if phase == 0:
		if phase_frame < 10:
			return false
		player = game.get_node("CharacterBody2D")
		label = game.get_node("HUD/PointsLabel")
		magnets = get_nodes_in_group("magnets")
		var points := _point_nodes()
		_check(points.size() == 6, "exactly 6 points spawned (got %d)" % points.size())
		_check(magnets.size() == 2, "two magnets in group (got %d)" % magnets.size())
		if magnets.size() < 2:
			_finish(false)
			return false
		var a: Node2D = magnets[0]
		var b: Node2D = magnets[1]
		_check(int(a.get("polarity")) != int(b.get("polarity")), "magnets have opposite polarities")
		var tex_north := "res://assets/object-POS.svg"
		var tex_south := "res://assets/object-NEG.svg"
		var expected_a := tex_north if int(a.get("polarity")) == 0 else tex_south
		var expected_b := tex_north if int(b.get("polarity")) == 0 else tex_south
		_check(a.get_node("Sprite2D").texture.resource_path == expected_a, "magnet A sprite matches its polarity")
		_check(b.get_node("Sprite2D").texture.resource_path == expected_b, "magnet B sprite matches its polarity")
		var near_a := 0
		for point in points:
			if point.global_position.distance_to(a.global_position) < point.global_position.distance_to(b.global_position):
				near_a += 1
		_check(near_a == 3, "3 points per magnet (%d / %d)" % [near_a, points.size() - near_a])
		nearest = a if player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position) else b
		other = b if nearest == a else a
		var spawn_distance: float = player.global_position.distance_to(nearest.global_position)
		_check(spawn_distance > 600.0 and spawn_distance < 1600.0, "player spawns near a magnet (%.0f px)" % spawn_distance)
		_check(int(player.current_polarity) != int(nearest.get("polarity")), "player polarity is opposite the nearby magnet")
		_check(player.points == 0, "no points collected on spawn (got %d)" % player.points)
		_check(label.text == "Pont: 0 / 6", "HUD starts at 0 / 6 (got '%s')" % label.text)
		phase = 7
		phase_frame = 0
		return false

	if phase == 7:
		if phase_frame == 1:
			player.global_position = nearest.global_position + Vector2(9000.0, 9000.0)
			player.velocity = Vector2.ZERO
		elif phase_frame > 120:
			nearest = magnets[0] if player.global_position.distance_to(magnets[0].global_position) < player.global_position.distance_to(magnets[1].global_position) else magnets[1]
			other = magnets[1] if nearest == magnets[0] else magnets[0]
			var rescued_distance: float = player.global_position.distance_to(nearest.global_position)
			_check(rescued_distance < 1600.0, "lost player is rescued near a magnet (%.0f px)" % rescued_distance)
			_check(int(player.current_polarity) != int(nearest.get("polarity")), "rescued player is attracted to the nearby magnet")
			Input.action_press("move_right")
			phase = 1
			phase_frame = 0
		return false

	if phase == 1:
		if _attached_to(nearest):
			phase = 2
			phase_frame = 0
		elif phase_frame > 300:
			_check(false, "player reached the nearby magnet")
			_finish(false)
		return false

	if phase == 2:
		if player.points >= 3:
			_check(player.points == 3, "collected the 3 points around the first magnet (got %d)" % player.points)
			_check(label.text == "Pont: 3 / 6", "HUD shows 3 / 6 (got '%s')" % label.text)
			Input.action_release("move_right")
			phase = 6
			phase_frame = 0
		elif phase_frame > 900:
			_check(false, "collected the 3 points around the first magnet (got %d)" % player.points)
			_finish(false)
		return false

	if phase == 6:
		var radial: Vector2 = (player.global_position - nearest.global_position).normalized()
		var toward_other: Vector2 = (other.global_position - nearest.global_position).normalized()
		if radial.dot(toward_other) > 0.98:
			print("INFO: flipping at alignment %.3f after %d frames" % [radial.dot(toward_other), phase_frame])
			player.current_polarity = 1 - int(other.get("polarity"))
			phase = 3
			phase_frame = 0
		elif phase_frame > 600:
			_check(false, "player orbited to face the second magnet")
			_finish(false)
		return false

	if phase == 3:
		if _attached_to(other):
			Input.action_press("move_right")
			phase = 4
			phase_frame = 0
		elif phase_frame > 1800:
			_check(false, "player reached the second magnet (%.0f px away)" % player.global_position.distance_to(other.global_position))
			_finish(false)
		return false

	if phase == 4:
		if player.points >= 6:
			_check(player.points == 6, "collected all 6 points (got %d)" % player.points)
			_check(label.text == "Pont: 6 / 6", "HUD shows 6 / 6 (got '%s')" % label.text)
			Input.action_release("move_right")
			phase = 5
			phase_frame = 0
		elif phase_frame > 900:
			_check(false, "collected the points around the second magnet (got %d)" % player.points)
			_finish(false)
		return false

	if phase == 5:
		if phase_frame > 120:
			_check(current_scene != null and current_scene.scene_file_path == "res://scenes/MainMenu.tscn", "returned to the main menu after collecting all points")
			_finish(failures.is_empty())
		return false

	return false

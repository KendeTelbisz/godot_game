extends CharacterBody2D

enum Polarity { NORTH, SOUTH }

@export var current_polarity: Polarity = Polarity.NORTH

@export_group("Mozgás")
@export var speed: float = 700.0
@export var acceleration: float = 6000.0
@export var air_acceleration: float = 4000.0
@export var friction: float = 9000.0
@export var jump_velocity: float = -1100.0

@export_group("Gravitáció")
@export var gravity: float = 2000.0
@export var max_fall_speed: float = 2200.0

@export_group("Mágnesesség")
@export var magnetic_strength_multiplier: float = 8000000000.0
@export var min_distance: float = 80.0
@export var max_magnetic_force: float = 20000.0
@export var magnetic_damping: float = 2.0
@export var max_magnetic_speed: float = 2500.0
@export var magnet_contact_tolerance: float = 24.0

@onready var PolarityCh := $change
@onready var pointCh := $point

@onready var magnet_sensor: Area2D = get_node_or_null("magnetSensor")
@onready var animator := $AnimatedSprite2D

var points: int = 0


func _ready() -> void:
	add_to_group("player")


func add_point() -> void:
	points += 1
	pointCh.play(0.3)
	


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_polarity"):
		if current_polarity == Polarity.NORTH:
			current_polarity = Polarity.SOUTH
			print("Pólus váltva: DÉL (SOUTH)")
			animator.animation = "NEG"
			PolarityCh.play()
			
		else:
			current_polarity = Polarity.NORTH
			print("Pólus váltva: ÉSZAK (NORTH)")
			PolarityCh.play()
			animator.animation = "POS"


func _physics_process(delta: float) -> void:
	var magnets := _overlapping_magnets()
	var attached := _find_attached_magnet(magnets)

	var attached_radial := Vector2.ZERO
	var attached_contact := 0.0
	if attached != null:
		attached_radial = _radial_from(attached)
		attached_contact = _contact_distance(attached)

	if attached == null and not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	var input_x := Input.get_axis("move_left", "move_right")
	if attached != null:
		var tangent := Vector2(-attached_radial.y, attached_radial.x)
		var slide_speed := velocity.dot(tangent)
		if not is_zero_approx(input_x):
			slide_speed = move_toward(slide_speed, input_x * max_magnetic_speed, acceleration * delta)
		velocity = tangent * slide_speed
	elif is_zero_approx(input_x):
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, input_x * speed, accel * delta)
	var magnetic_force := Vector2.ZERO

	for area in magnets:
		var offset: Vector2 = area.global_position - global_position
		var distance := maxf(offset.length(), min_distance)
		var direction := offset / distance
		var magnet_polarity = area.get("polarity")

		var polarity_dir := 1.0 if current_polarity != magnet_polarity else -1.0

		var force_magnitude := magnetic_strength_multiplier / (distance * distance)
		force_magnitude = minf(force_magnitude, max_magnetic_force)

		magnetic_force += direction * force_magnitude * polarity_dir

	velocity += magnetic_force * delta

	if not magnetic_force.is_zero_approx():
		var field_dir := magnetic_force.normalized()
		var radial_speed := velocity.dot(field_dir)
		velocity -= field_dir * radial_speed * minf(1.0, magnetic_damping * delta)

	if attached != null:
		velocity -= attached_radial * velocity.dot(attached_radial)

	velocity = velocity.limit_length(max_magnetic_speed)

	move_and_slide()

	if attached != null:
		var radial := _radial_from(attached)
		var tangent := Vector2(-radial.y, radial.x)
		if tangent.dot(velocity) < 0.0:
			tangent = -tangent
		var slide_speed := velocity.length()
		global_position = attached.global_position + radial * attached_contact
		velocity = tangent * slide_speed


func _overlapping_magnets() -> Array:
	var result: Array = []
	if magnet_sensor == null:
		return result
	for area in magnet_sensor.get_overlapping_areas():
		if area.is_in_group("magnets"):
			result.append(area)
	return result


func _find_attached_magnet(magnets: Array) -> Area2D:
	for area in magnets:
		if current_polarity == area.get("polarity"):
			continue
		if global_position.distance_to(area.global_position) <= _contact_distance(area) + magnet_contact_tolerance:
			return area
	return null


func _radial_from(area: Area2D) -> Vector2:
	var radial := global_position - area.global_position
	if radial.is_zero_approx():
		return Vector2.UP
	return radial.normalized()


func _contact_distance(area: Area2D) -> float:
	return _first_circle_radius(area) + _first_circle_radius(self)


func _first_circle_radius(node: Node) -> float:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return (child.shape as CircleShape2D).radius
	return 0.0

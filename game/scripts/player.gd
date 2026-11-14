extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
# A játékos scriptjében (CharacterBody2D)

enum Polarity { NORTH, SOUTH }
@export var current_polarity: Polarity = Polarity.NORTH

@export var magnetic_multiplier: float = 1000.0 # Finomhangoláshoz

func _physics_process(delta: float) -> void:
	# ... itt fut a szokásos gravitáció és mozgás ...
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Mágneses erők begyűjtése a közelben lévő mezőkről
	#apply_magnetic_forces(delta)
	
	move_and_slide()
"""
func apply_magnetic_forces(delta: float) -> void:
	for magnet in active_magnets:
		var direction_to_magnet = global_position.direction_to(magnet.global_position)
		var distance = global_position.distance_to(magnet.global_position)
		
		if distance < 1.0: 
			continue
			
		var polarity_multiplier = 1.0
		if current_polarity == magnet.polarity:
			polarity_multiplier = -1.0
		else:
			polarity_multiplier =  1.0
		var force_magnitude = (magnet.strength / (distance * distance)) * magnetic_multiplier
		velocity -= direction_to_magnet * force_magnitude * polarity_multiplier * delta
"""

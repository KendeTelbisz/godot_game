extends Area2D

enum Polarity { NORTH, SOUTH }
@export var polarity: Polarity = Polarity.NORTH

func _ready() -> void:
	# Biztos ami biztos, programból is beletesszük a csoportba
	if not is_in_group("magnets"):
		add_to_group("magnets")

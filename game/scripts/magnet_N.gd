extends Area2D

enum Polarity { NORTH, SOUTH }
@export var polarity: Polarity = Polarity.SOUTH

func _ready() -> void:
	if not is_in_group("magnets"):
		add_to_group("magnets")

extends Area2D

signal hit


func _ready() -> void:
	if not is_in_group("hazards"):
		add_to_group("hazards")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hit.emit()

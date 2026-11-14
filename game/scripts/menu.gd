extends Control

const GameData := preload("res://scripts/game_data.gd")

@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	GameData.reload()
	score_label.text = "Pont: %d" % GameData.get_points()

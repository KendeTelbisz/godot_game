extends Control

const GameData := preload("res://scripts/game_data.gd")
const MAIN_MENU := "res://scenes/MainMenu.tscn"

const ITEMS := [
	{
		"id": "speed",
		"name": "Gyorsaság",
		"stat": "speed",
		"step": 100.0,
		"base_cost": 10,
		"cost_step": 5,
	},
	{
		"id": "jump",
		"name": "Ugrás",
		"stat": "jump_velocity",
		"step": -150.0,
		"base_cost": 10,
		"cost_step": 5,
	},
	{
		"id": "magnet_force",
		"name": "Mágnes erő",
		"stat": "magnetic_strength_multiplier",
		"step": 2000000000.0,
		"base_cost": 15,
		"cost_step": 10,
	},
	{
		"id": "magnet_speed",
		"name": "Mágnes sebesség",
		"stat": "max_magnetic_speed",
		"step": 250.0,
		"base_cost": 15,
		"cost_step": 10,
	},
]

@onready var points_label: Label = $PointsLabel
@onready var message_label: Label = $MessageLabel
@onready var back_button: Button = $BackButton
@onready var music := $AudioStreamPlayer2D
var rows: Array = []


func _ready() -> void:
	music.play()
	GameData.reload()
	for index in ITEMS.size():
		var row := {
			"item": ITEMS[index],
			"name_label": get_node("Items/Item%d/NameLabel" % index),
			"price_label": get_node("Items/Item%d/PriceLabel" % index),
			"buy_button": get_node("Items/Item%d/BuyButton" % index),
		}
		row["buy_button"].pressed.connect(_on_buy_pressed.bind(index))
		rows.append(row)
	back_button.pressed.connect(_on_back_pressed)
	_refresh()


func _cost(item: Dictionary) -> int:
	return int(item["base_cost"]) + GameData.get_shop_level(item["id"]) * int(item["cost_step"])


func _refresh() -> void:
	points_label.text = "Pont: %d" % GameData.get_points()
	for row in rows:
		var item: Dictionary = row["item"]
		var cost := _cost(item)
		row["name_label"].text = "%s (szint %d)" % [item["name"], GameData.get_shop_level(item["id"])]
		row["price_label"].text = "%d pont" % cost
		row["buy_button"].disabled = GameData.get_points() < cost


func _on_buy_pressed(index: int) -> void:
	var item: Dictionary = rows[index]["item"]
	var cost := _cost(item)
	if not GameData.spend_points(cost):
		message_label.text = "Nincs elég pontod!"
		return
	GameData.add_player_stat(item["stat"], item["step"])
	GameData.add_shop_level(item["id"])
	message_label.text = "%s fejlesztve!" % item["name"]
	_refresh()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

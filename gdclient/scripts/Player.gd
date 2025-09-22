extends Node2D

var player_id: int = 0
var player_name: String = ""

func setup(id: int, name: String, color: Color):
	player_id = id
	player_name = name
	
	$ColorRect.color = color
	$NameLabel.text = name
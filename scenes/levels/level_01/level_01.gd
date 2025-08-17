@tool
extends Node2D
class_name Level


func _ready():
	scale = Vector2(GameManager.screen_scale, GameManager.screen_scale)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		scale = Vector2(GameManager.screen_scale, GameManager.screen_scale)

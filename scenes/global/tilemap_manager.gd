@tool
extends Node2D

@export var background_lightness: float = 1.0:
	set(value):
		background_lightness = value
		_update_background_modulate()


@onready var background_group := $background
@onready var foreground_group := $foreground


func _ready():
	background_group.modulate = Color(background_lightness, background_lightness, background_lightness)

func _process(_delta):
	if Engine.is_editor_hint():
		background_group.modulate = Color(background_lightness, background_lightness, background_lightness)

func _update_background_modulate():
	if not is_inside_tree():
		return
	background_group.modulate = Color(background_lightness, background_lightness, background_lightness)

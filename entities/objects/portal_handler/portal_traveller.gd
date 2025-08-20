@tool
extends Node2D
class_name PortalTravellerHelper

@export var sprite_node: NodePath
var sprite: AnimatedSprite2D

func _ready():
	if sprite_node != NodePath():
		sprite = get_node(sprite_node)
		# Do something with the selected child node

func get_sprite() -> AnimatedSprite2D:
	if sprite_node != NodePath():
		return get_node(sprite_node)
	else:
		return null

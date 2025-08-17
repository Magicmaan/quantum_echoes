@tool
extends Node2D
class_name SpriteShadow
@onready var sprite: AnimatedSprite2D = get_parent()
@onready var texture_rect: TextureRect = $shadow_sprite


@export var offset: Vector2 = Vector2(-1,1):
	set(value):
		offset=value
@export var opacity: float = 1.0:
	set (value):
		opacity=value

var original_position := Vector2.ZERO

func _ready():
	original_position = position
	modulate = Color(0.0,0.0,0.0,opacity)
	#position += offset
	
	texture_rect.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func _process(_delta):
	#if Engine.is_editor_hint():
		#modulate = Color(0.0,0.0,0.0,opacity)
		#position = offset
		#texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	
	texture_rect.flip_h = sprite.flip_h
	texture_rect.flip_v = sprite.flip_v
	

func _on_sprite_animation_changed() -> void:
	assert (sprite is AnimatedSprite2D)
	print("anim")


func _on_sprite_frame_changed() -> void:
	assert (sprite is AnimatedSprite2D)
	texture_rect.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	texture_rect.size = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_size()
	
	
	

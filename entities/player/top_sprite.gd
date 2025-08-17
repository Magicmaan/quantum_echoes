extends AnimatedSprite2D


@onready var parent_sprite: AnimatedSprite2D = get_parent()

func _ready():
	if not (parent_sprite is AnimatedSprite2D):
		print("top sprite parent is not AnimatedSprite2D")
	parent_sprite.animation_changed
	parent_sprite.frame_changed
	parent_sprite.connect("frame_changed",_on_frame_changed)
	parent_sprite.connect("animation_changed",_on_animation_changed)

func _process(_delta):
	flip_h = parent_sprite.flip_h
	flip_v = parent_sprite.flip_v

func _on_frame_changed():
	frame = parent_sprite.frame

func _on_animation_changed():
	animation = parent_sprite.animation

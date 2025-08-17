extends AnimatedSprite2D

@export var head_pixels := {
	"idle": [Vector2(0,0),Vector2(-1,1),Vector2(0,1),],
	"walk": [Vector2(1,0),Vector2(1,1),Vector2(1,0),Vector2(-1,-1),Vector2(0,-1),Vector2(-1,-1),],
	"jump": [],
	"crouch": [],
	"hold": [Vector2(0,0),Vector2(-1,1),Vector2(0,1),],
}

#@onready var arm_sprite = get_parent().get_node("arm_sprite")
@onready var arm_sprite = Sprite2D.new()

var current_frame_index := 0



	
	#
	#var normal_texture = load("res://Assets/Spritesheet/normal_chell_spritesheet.png")
	#
	#sprite_frames.set_

	

func _on_frame_changed():
	current_frame_index = frame  # Now you can safely use it

func get_head_pixel():
	var anim = animation
	var frame = current_frame_index
	#print("Anim ", anim)
	if head_pixels.has(anim) and frame < head_pixels[anim].size():
		return head_pixels[anim][frame]
	return null


func _on_animation_changed() -> void:
	pass # Replace with function body.

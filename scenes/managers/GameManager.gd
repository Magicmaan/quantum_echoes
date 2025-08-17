# This script is an autoload, that can be accessed from any other script!
extends Node2D




var score : int = 0

signal gravity_changed(new_gravity)
@export var gravity: float = 15:
	set(value):
		gravity = value
		emit_signal("gravity_changed",value)

var gravity_horizontal: Vector2 = Vector2.ZERO

signal gravity_direction_changed(new_direction)
@export var gravity_direction: Vector2 = Vector2.DOWN:
	set(value):
		if value == Vector2.ZERO:
			value = Vector2.DOWN
		gravity_direction = value
		gravity_horizontal = value.orthogonal().normalized()
		emit_signal("gravity_direction_changed",value)



@export var show_fps: bool = true
@onready var fps_label: Label = $fps_counter

@export var screen_scale: float = 2.0

enum Orientation {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

const ORIENTATION_VECTORS = {
	Orientation.LEFT: Vector2.LEFT,
	Orientation.RIGHT: Vector2.RIGHT,
	Orientation.UP: Vector2.UP,
	Orientation.DOWN: Vector2.DOWN
}


func _ready():
	#DisplayServer.window_set_size(Vector2i(256*3,144*3))
	print("Game Manager ready")

func _enter_tree() -> void:
	if GameManager != self:
		queue_free()

# Adds 1 to score variable
func add_score():
	score += 1

func _process(delta: float) -> void:
	if is_instance_valid(fps_label):
		fps_label.text = str(Engine.get_frames_per_second()).to_upper()

# Loads next level
func load_next_level(next_scene : PackedScene):
	get_tree().change_scene_to_packed(next_scene)

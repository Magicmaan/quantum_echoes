@tool
extends PointLight2D

var texture_path = "res://assets/entities/lights"


@export var dither: bool = true:
	set (value):
		dither = value
		$texture_rect.visible = value
@export var size: int = 4:
	set (value):
		size = value
		_update_size()


@onready var sizes_list := [
	16,32,64,128,256,512,1024,2048
]
#@onready var texture_rect: TextureRect = $texture_rect

func get_image() -> Texture2D:
	var rounded = size
	#rounded /= len(sizes_list)
	#print("rounded value ", rounded)
	
	var actual_size = sizes_list.get(size)
	
	var texture := load("res://assets/entities/lights/light_"+str(actual_size)+".png")
	#print(texture)
	return texture

func _update_size():
	var image = get_image()
	var s = sizes_list.get(size)
	if !s:
		s = 64
	texture = image
	
	
func _ready():
	await get_tree().process_frame

func _process(_delta):
	_update_size()

extends Node2D

@export var slow_factor: float = 0.25

var old_position: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	var parent = get_parent()
#	should probably find a better way for this
	var camera: Camera2D = parent.get_node("%camera")
	var camera_position = camera.get_screen_center_position()
	#print(camera.global_position)
	
	var camera_delta = old_position - camera_position
	
	#print(old_position)
	#print(camera.global_position)
	#print("delta ",camera_delta)
	old_position.x = camera_position.x
	old_position.y = camera_position.y
	if abs(camera_delta.x) > 100:
		return
	$Parallax2D/ColorRect.position.x += camera_delta.x * 2.5
	
	

	#for i in get_child_count():
		#var cam: Camera2D = $parallax_0/Camera2D
		
		#cam.global_position = camera.global_position
		#node.offset.y = camera_position.y
	
	#$parallax_0/Camera2D.global_position = camera.global_positionss 

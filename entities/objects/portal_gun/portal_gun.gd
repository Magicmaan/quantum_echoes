extends RigidBody2D

var direction: int = -1
var direction_vector: float = 1

@onready var parent := get_parent()

var _is_equipped: bool = false
var attach_point: Marker2D = Marker2D.new()

func _ready() -> void:
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	
	
func _process(_delta):
	if attach_point:
		direction = attach_point.get_meta("flip_h")
		direction_vector = -1 if direction else 1
	update_sprite(_delta)
	face_mouse()
	
	process_right_click()
	process_left_click()
	queue_redraw()

func update_sprite(_delta):
	#var parent = get_parent()
	#global_position = attach_point.global_position
	$sprite.flip_h = direction
	
	if direction:
		$RayCast2D.target_position.x = -abs($RayCast2D.target_position.x)
	else:
		$RayCast2D.target_position.x = abs($RayCast2D.target_position.x)
	
	if attach_point:
		$sprite.global_position = attach_point.global_position
	#if parent is Marker2D:
		#flip_h = parent.get_meta("flip_h",false)
	
func face_mouse():
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	global_rotation = mouse_direction.angle()
	if direction:
		global_rotation += PI

#func _draw():
	#draw_line(Vector2.ZERO, Vector2(direction_vector,0)*(100), Color.RED)

func process_right_click():
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	
	var raycast_position = raycast_tilemap()
	if !raycast_position:
		return

	var raycast_normal = $RayCast2D.get_collision_normal()
	%portalHandler.place_portal("orange", raycast_position, raycast_normal)

func process_left_click():
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	
	var raycast_position = raycast_tilemap()
	if !raycast_position:
		return

	var raycast_normal = $RayCast2D.get_collision_normal()
	%portalHandler.place_portal("blue", raycast_position, raycast_normal)

func _notification(notification: int) -> void:
	if notification == NOTIFICATION_PARENTED:
		parent = get_parent()
		attach_point = null
		for child in parent.get_children():
			if child.is_in_group("attach_point"):
				attach_point = child
		
		if attach_point == null:
			print("portal gun parent has no attach point, ensure this is intentional")

func raycast_tilemap():
	if $RayCast2D.is_colliding():
		var collision_point = $RayCast2D.get_collision_point()
		var dir = (collision_point - global_position).normalized()
#		adjust offset as raycast can return position embedded within tile,
#		so small offset to put it out
		var offset_distance = 8  # Adjust this value as needed
		var adjusted_point = collision_point - dir * offset_distance
		return adjusted_point
	
	return Vector2.ZERO
func place_portal(position):
	pass

func _draw() -> void:
	draw_line(Vector2.ZERO, get_local_mouse_position(), Color.GREEN,2)

extends RigidBody2D

@export var target_rotation: float = -45.0:
	set (value):
		target_rotation = value
@onready var original_position = position



func _physics_process(_delta: float) -> void:
	#var val:float = sin(Time.get_ticks_msec()/1000.0)*10.0;
	#position = original_position
	##apply_torque(val)
	##print(val)
	#print(target_rotation)
	#print("rotation ", rotation_degrees)
	if rotation_degrees-randf_range(5.0,-5.0) < target_rotation:
		apply_torque(1000.0)
	elif rotation_degrees+randf_range(5.0,-5.0) > target_rotation:
		apply_torque(-1000.0)
	
	#angular_velocity = 0.0
	

extends RigidBody2D




@export var can_shoot: bool = true
@export var found_delay: float = 3.0
@export var lost_delay: float = 3.0


var gravity = GameManager.gravity

var is_shooting: bool = false
var is_panicking: bool = false
enum TargetState { NONE, FOUND, LOST, MEGA_LOST, RECOVERED, FOCUS }
var current_target_state: TargetState = TargetState.NONE

var found_timer: float = 0.0
var lost_timer: float = 0.0

var target: Node2D = null
var target_focus_marker: Marker2D = null
@onready var areacast: Area2D = $area_cast
@onready var ray_line: Line2D = $Line2D


func _physics_process(_delta):
	movement(_delta)

func movement(_delta):
	if floor:
		linear_velocity.y += gravity

func _process(_delta):

	# user enters sights -> FOUND
	# user stays in sights for a while -> FOCUS
	# user leaves sights -> LOST
	# user is not found for a while -> MEGA_LOST (unrecoverable)
	# user is found again after being lost -> RECOVERED
	if target:
		match current_target_state:
			TargetState.FOUND:
				found_timer += _delta
				on_target_found(_delta)
				
			TargetState.LOST:
				lost_timer += _delta
				on_target_lost(_delta)
				
			TargetState.RECOVERED:
				on_target_recovered(_delta)


func shoot():
	if can_shoot and !is_shooting:
		is_shooting = true
		print("Shooting!")
		# Add shooting logic here
		await get_tree().create_timer(0.5).timeout
		is_shooting = false

func on_target_found(_delta):
	var col1 = Vector3(1,1,1)
	var col2 = Vector3(0.5,0.5,0.5)  # Dimmer white
	var freq = lerp(2.0, 0.01, clamp(found_timer / 2.0, 0, 1))  # Frequency decreases as found_timer increases
	var mix = sin(found_timer * min(found_timer,5.0)) + 1.0
	mix = mix / 2.0  # Normalize to [0, 1]
	var vec = col1.lerp(col2, mix)
	ray_line.modulate = Color(vec.x, vec.y, vec.z)

	var target_position = target.global_position
	if target_focus_marker:
		target_position = target_focus_marker.global_position
	var local_target = ray_line.to_local(target_position)
	ray_line.set_point_position(1, local_target)

	

func on_target_lost(_delta):
	# print ("Target lost: ", target.name)
	ray_line.default_color = Color(1, 0, 0)  # Red line for lost target


func on_target_recovered(_delta):
	
	await get_tree().create_timer(0.5).timeout
	# print("Target recovered: ", target.name)
	if current_target_state == TargetState.RECOVERED:
		current_target_state = TargetState.FOUND

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# print("collided with player")
		var random_angle = randf_range(-0.75,0.75)
		
		var on_top_falloff = 1
		
		
		if position.y > body.position.y:
			on_top_falloff = 0.25
		
		# print("on top? ", on_top_falloff)
		
		var vel = randf_range(100,300)
		
		angular_velocity += random_angle * on_top_falloff
		linear_velocity.y -= 300 * on_top_falloff
		linear_velocity.x += vel * body.direction_vector * (on_top_falloff)


func _on_area_cast_entered(body: Node2D) -> void:
	if body.is_in_group("targetable"):
		# print("Area cast entered by: ", body.name)
		target = body
		var focus = body.get_node_or_null("focus_point")
		if focus:
			target_focus_marker = focus
		else:
			target_focus_marker = null

		found_timer = 0.0
		if current_target_state == TargetState.NONE:
			current_target_state = TargetState.FOUND
		elif current_target_state == TargetState.LOST:
			current_target_state = TargetState.RECOVERED

func _on_area_cast_exited(body: Node2D) -> void:
	if body.is_in_group("targetable"):
		lost_timer = 0.0
		# print("Area cast exited by: ", body.name)
		if body == target:
			current_target_state = TargetState.LOST

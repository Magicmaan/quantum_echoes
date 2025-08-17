class_name Player
extends CharacterBody2D

# --------- VARIABLES ---------- #

@export_category("Player Properties") # You can tweak these changes according to your likings
@export var max_move_speed : float = 400

@export var max_jump_count : int = 2
var jump_count : int = 2

@export_category("Player Movement") # You can tweak these changes according to your likings
@export var move_accel: float = 800
@export var move_decel: float = 1200
@export var direction_change_decel: float = 1600

@export var small_jump_force: float = 400
@export var large_jump_force: float = 600
@export var coyote_time: float = 0.128 # How long the player can jump after leaving the ground (in milliseconds)
@export var jump_force_delay: float = 0.128 # How long the player can hold the jump button to charge a jump (in seconds)


@export_category("Toggle Functions") # Double jump feature is disable by default (Can be toggled from inspector)
@export var double_jump: bool = false

# if player direction should follow mouse
@export var follow_mouse: bool = true
# if mouse should stay relative position if moving
# TODO
@export var anchor_mouse: bool = false

# --------- INTERNAL VARIABLES ---------- #
var gravity: float = GameManager.gravity
var gravity_direction: Vector2 = GameManager.gravity_direction
var movement_enabled: bool = true
var jump_enabled: bool = true
var is_grounded: bool = false
var is_moving: bool = false
var is_jumping: bool = false
var is_crouching: bool = false
var input_horizontal: float = 0.0
var input: Vector2 = Vector2.ZERO
var direction: bool = false
var direction_vector: int = 1
var is_holding: bool = true

var horizontal_direction: Vector2 = Vector2.LEFT
var horizontal_velocity: float = 0.0
var vertical_velocity: float = 0.0



# jumping variables
var is_jump_held: bool = false
var jump_hold_time: float = 0.0
var time_off_ground: float = 0.0
var can_jump: bool = true

# PREVIOUS FRAME VARIABLES
var _previous_velocity = Vector2.ZERO

@onready var player_sprite: AnimatedSprite2D = $sprite
@onready var spawn_point = %SpawnPoint
#@onready var particle_trails = $ParticleTrails
#@onready var death_particles = $DeathParticles
@onready var attach_point = $attach_point
@onready var _original_attach_point_position: Vector2 = attach_point.position
var attach_point_distance = -99
# --------- BUILT-IN FUNCTIONS ---------- #
func _ready():
	GameManager.gravity_changed.connect(func(new_gravity): gravity = new_gravity)
	GameManager.gravity_direction_changed.connect(func(new_direction): gravity_direction = new_direction)
	
	
	attach_point_distance = $attach_point.position.x - player_sprite.position.x
	#print("original distance ", attach_point_distance)
	$camera.make_current()
	
func _physics_process(_delta):
	up_direction = -gravity_direction.normalized()
	horizontal_direction = gravity_direction.orthogonal().normalized()
	horizontal_velocity = velocity.dot(horizontal_direction)
	vertical_velocity = velocity.dot(up_direction)
	
	
	if is_on_floor():
		is_grounded = true
		time_off_ground = 0
	else:
		is_grounded = false
		time_off_ground += _delta

	is_moving = abs(velocity.dot(horizontal_direction)) > 0
	is_jumping = abs(velocity.dot(up_direction)) > 0
	is_crouching = Input.is_key_pressed(KEY_CTRL)
	input_horizontal = Input.get_axis("left", "right")
	input = Input.get_vector("left","right","jump","crouch")
	
	
	if _previous_velocity != velocity:
		_previous_velocity = velocity
	
	
	movement(_delta)
#	preserve direction on stop
	if abs(horizontal_velocity) > 0 :
		direction = horizontal_velocity < 0
		
		#if direction:
			#direction_vector = -1
		#else:
			#direction_vector = 1
	else:
		if follow_mouse:
			var mouse_direction = (get_global_mouse_position() - global_position).normalized()
			var angle_from_center = mouse_direction.angle_to(up_direction)
			#print("direction: ", (angle_from_center))
			direction = true if angle_from_center > 0 else false
	
	direction_vector = -1 if direction else 1

func _process(_delta):
	update_sprite()
	update_attach_point()
	
	
# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement(_delta):
	# Gravity
	if !is_on_floor():
		velocity += gravity * -up_direction

	handle_jumping(_delta)
	handle_moving(_delta)

	move_and_slide()

func handle_moving(_delta):
	
	## clamp the velocity to max_move_speed
	#velocity.x = clamp(velocity.x, -max_move_speed, max_move_speed)
	if not movement_enabled:
		# Remove velocity along horizontal direction
		velocity -= velocity.project(horizontal_direction)
		return

	#var horiz_vel = velocity.dot(horizontal_direction)

	if input.x == 0:
		var decel_vector: float = move_decel * _delta
		if abs(horizontal_velocity) <= decel_vector:
			horizontal_velocity = 0
		else:
			horizontal_velocity -= decel_vector * sign(horizontal_velocity)
		horizontal_velocity = floor(horizontal_velocity)
	else:
		var velocity_direction = sign(horizontal_velocity)

		# Rapid deceleration when switching directions
		if sign(input.x) != velocity_direction:
			horizontal_velocity -= direction_change_decel * _delta * velocity_direction
		# Accelerate
		horizontal_velocity += input.x * move_accel * _delta

	# Clamp horizontal velocity
	horizontal_velocity = clamp(horizontal_velocity, -max_move_speed, max_move_speed)

	# Reconstruct full velocity vector: combine horizontal with vertical
	var vertical_velocity = velocity - velocity.project(horizontal_direction)
	velocity = vertical_velocity + horizontal_direction * horizontal_velocity



# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping(_delta):
	if !jump_enabled or !movement_enabled:
		return
	
	# on jump click, start counting time held
	if Input.is_action_just_pressed("jump"):
		is_jump_held = true
		jump_hold_time = 0
		# used to prevent jumping again if held too long
		# i.e. if player holds jump for too long, they can't jump again until released
		can_jump = true
	
	# if is held, increase the hold time
	if Input.is_action_pressed("jump") and is_jump_held:
		jump_hold_time += _delta

	# jump on release or max charge time
	if (Input.is_action_just_released("jump") or jump_hold_time >= jump_force_delay) and can_jump :
		
		if is_grounded or (time_off_ground <= coyote_time and !is_jumping):
			if jump_hold_time >= jump_force_delay:
				# Long jump
				velocity += large_jump_force * up_direction
			else:
				# Short jump
				velocity += small_jump_force * up_direction

			can_jump = false
			is_jump_held = false
			jump_hold_time = 0

		


	


func update_sprite():
#	 correct rotation to match the gravity yk
	rotation = (-up_direction.orthogonal()).angle()
	
# 	Handle Player Animations
	if is_grounded:
		if is_crouching:
			player_sprite.play("crouch" if !is_holding else "hold")
		else:
			if abs(horizontal_velocity) > 0:
				
				player_sprite.play("walk")
			else:
				player_sprite.play("idle" if !is_holding else "hold")
	if is_jumping:
		print(player_sprite.animation, player_sprite.animation_finished)
		#if player_sprite.animation
		player_sprite.play("jump")
		
	
	# Flip player sprite based on X velocity
	player_sprite.flip_h = direction
	
	
	

	
func update_attach_point():
#	mirror the position of attach point if flipped
	#print("position before ", attach_point.position)
	#var distance = attach_point.position.x - player_sprite.position.x
	attach_point.position = _original_attach_point_position
#
	var offset = player_sprite.get_head_pixel()
	if offset != null:
		attach_point.position.x += offset.x * sign(attach_point.position.x)
		attach_point.position.y += offset.y
	
	if direction:
		attach_point.position.x = -abs(attach_point.position.x)
		attach_point.set_meta("flip_h", true)
	else:
		attach_point.position.x = abs(attach_point.position.x)
		attach_point.set_meta("flip_h", false)
	
	#print("position after ", attach_point.position)
# Tween Animations
func death_tween():
	movement_enabled = false
	var tween = create_tween()
	tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	audio_manager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(player_sprite, "scale", Vector2(2,2), 0.15) 
	tween.parallel().tween_property(player_sprite, "position", Vector2(0,-32), 0.15)

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

# --------- SIGNALS ---------- #
# Reset the player's position to the current level spawn point if collided with any trap
func _on_object_collision_body_entered(body):
	if body.is_in_group("Traps"):
		audio_manager.death_sfx.play()
		death_tween()

func _on_animation_changed():
	update_attach_point()

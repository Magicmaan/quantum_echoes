@tool
extends Area2D
class_name GenericPortal

@export var funnel_length: float = 16.0:
	set(value):
		funnel_length = value
		update_funnel()
@export var funnel_width: float = 16.0:
	set(value):
		funnel_width = value
		update_funnel()
@export var funnel_pull_strength: float = 1.0


@onready var travellers_container = $travellers_container
@onready var collision_container: StaticBody2D = $collision_container


var active: bool = false
var orientation: Vector2 = Vector2(1, 0)

func clear_collisions():
	for child in collision_container.get_children():
		collision_container.remove_child(child)
		child.queue_free()

func add_collision(position: Vector2, size: Vector2 = Vector2(32, 32)):
	collision_container.global_rotation = 0
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.global_position = position
	
	collision_container.add_child(collision)
	
	# Add a visual cube (ColorRect as a simple cube representation)
	var cube_visual := ColorRect.new()
	cube_visual.color = Color(1.0,0.0,0.0,1.0)

	if size.x == 32 and size.y == 32:
		cube_visual.color = Color(0.0, 1.0, 0.0, 1.0)  # Green for custom size

	cube_visual.size = size
	cube_visual.global_position = (position) - cube_visual.size / 2
	cube_visual.z_index = 1000000
	cube_visual.z_as_relative = false
	collision_container.add_child(cube_visual)
	
	# print("Added collision at ", position)

func update_funnel():
	
	var tree = get_tree()
	if tree == null:
		return
	await tree.physics_frame
	print("hell yeah")
	await tree.process_frame
	var new_points = PackedVector2Array([
		Vector2(0,16),
		Vector2(0,-16),
		
		Vector2(funnel_length, -funnel_width),
		Vector2(funnel_length,funnel_width)
	])
	$funnel_cone/CollisionPolygon2D.set_polygon(new_points)
	


func _on_funnel_cone_body_entered(body: Node2D) -> void:
	if !body.is_in_group("portal_traveller"):
		return
	if !(body is RigidBody2D or body is CharacterBody2D):
		return
	print(body)
	var entity: CharacterBody2D = body as CharacterBody2D
	var direction = entity.global_position - global_position
	entity.velocity += -direction * 5


func _on_funnel_cone_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

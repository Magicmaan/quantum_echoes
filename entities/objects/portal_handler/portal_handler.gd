extends CanvasGroup

@onready var orange_portal: GenericPortal = $orange_portal
@onready var blue_portal: GenericPortal = $blue_portal 
@onready var portal_size: float = orange_portal.get_node("CollisionShape2D").shape.size.y
@onready var portal_size_overhang: float = (portal_size - 16.0) / 2.0

# pair of object,original, host portal, other portal
# this is used to keep track of portal travellers, so they can be moved between portals
# and to remove them when they are too far away from the portal
var portal_travellers: Array = []

# 
# 	portal placing functions
# 

func _ready() -> void:
	orange_portal.connect("body_entered", func (x): _generic_portal_body_entered(x, orange_portal, blue_portal))
	orange_portal.connect("body_exited", func (x): _generic_portal_body_exited(x, orange_portal))
	blue_portal.connect("body_entered", func (x): _generic_portal_body_entered(x, blue_portal, orange_portal))
	blue_portal.connect("body_exited", func (x): _generic_portal_body_exited(x, blue_portal))

func place_portal(portal: String, raycast_position: Vector2, raycast_normal: Vector2, recursive: bool = false) -> bool:
	return await place_portal_grid_aligned(portal, raycast_position, raycast_normal, recursive)


func place_portal_grid_aligned(portal: String, raycast_position: Vector2, raycast_normal: Vector2, recursive: bool) -> bool:
	# Grid aligned portal placement function
	# Places portal at closest grid position to raycast position, aligned to raycast normal
	var tilemap: TileMapLayer = %tilemaps/foreground/foreground_0
	var orientation = GameManager.ORIENTATION_VECTORS[determine_tile_face(raycast_normal)]
	
	# Get local cell position in tilemap
	var cell_position = tilemap.local_to_map(tilemap.to_local(raycast_position))
	var cell_id = tilemap.get_cell_source_id(cell_position)
	
	if cell_id > -1:
		print("Invalid position: ", cell_position)
		return false

	# Get world position of cell and center portal on grid
	var grid_position = tilemap.to_global(tilemap.map_to_local(cell_position))
	grid_position += Vector2(0, 16).rotated(orientation.angle())

	

	# Check surrounding tiles for valid placement
	var neighbors = [
		tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position, TileSet.CELL_NEIGHBOR_TOP_SIDE)) > -1,
		tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)) > -1,
		tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position, TileSet.CELL_NEIGHBOR_LEFT_SIDE)) > -1,
		tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)) > -1
	]
	if not neighbors.any(func(x): return x):
		return false

	# portal is 2 tall, so we need to check other cell aswell
	# this is to ensure that the portal is placed on valid tiles
	# Check if adjacent cells are suitable for portal placement
	#
	# 
	# | other tile
	# | main tile (this tile is the one we are placing the portal on)
	# 
	var other_cell = Vector2i(Vector2(0, 1).rotated(orientation.angle()))
	var other_cell_position = cell_position + other_cell
	var other_cell_occupied = tilemap.get_cell_source_id(other_cell_position) > -1

	var anchor_cell = Vector2i(Vector2(-1, 0).rotated(orientation.angle()))
	var anchor_position = other_cell_position + anchor_cell
	var anchor_not_occupied = tilemap.get_cell_source_id(anchor_position) == -1

	# Handle invalid placement with retry logic
	# retrys the logic on the other portal cell to find a valid position
	# this is because code only checks the main tile and associated top tile, but not the bottom side
	#  without it, tiles fail to place in corners always
	if other_cell_occupied or anchor_not_occupied:
		print("Adjacent cell occupied: ", other_cell_position)
		if recursive:
			return false
		
		var retry_position = raycast_position + Vector2(0, -32).rotated(orientation.angle())
		await place_portal_grid_aligned(portal, retry_position, raycast_normal, true)
		await get_tree().create_timer(2.0).timeout
		return false

	# Calculate final positions
	var portal_position = grid_position
	var grid_reference = grid_position - Vector2(16, 0).rotated(orientation.angle())
	
	# Place the portal
	var target_portal = orange_portal if portal == "orange" else blue_portal
	if not target_portal:
		print("Unknown portal type: ", portal)
		return false
	
	target_portal.visible = false
	
	if portal == "orange":
		place_orange(portal_position, orientation, grid_reference)
	else:
		place_blue(portal_position, orientation, grid_reference)
	
	target_portal.visible = true
	make_surrounding_collisions(portal_position, target_portal)

	return true

func place_portal_soft_aligned(portal: String, raycast_position: Vector2, raycast_normal: Vector2, recursive: bool = false) -> bool:
	# this is a soft aligned portal placement function
	# it will place the portal at the closest position to the raycast position
	# and will align it to the raycast normal
	# it will not snap to the grid, but will try to align to the closest tile

	# the collision shape however has issues because I am stupid
	
	var tilemap: TileMapLayer = %tilemaps/foreground/foreground_0
	# print(tilemap)
	# get local cell position in tilemap (0,0 is top-left corner of tilemap)
	var cell_position = tilemap.to_local(raycast_position)
	cell_position = tilemap.local_to_map(cell_position)
	var cell_id = tilemap.get_cell_source_id(cell_position)
	if cell_id > -1:
		print("not valid position: ", cell_position)
		return false

	# get the position of cell in map (1,1) -> (16,16) etc
	var grid_position = tilemap.map_to_local(cell_position)
	grid_position = tilemap.to_global(grid_position)		
	
	
	# surrounding tiles
	var top_right = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER)) > -1
	var bottom_right = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER)) > -1
	var top_left = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER)) > -1
	var bottom_left = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER)) > -1
	var top = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_TOP_SIDE)) > -1
	var bottom = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)) > -1
	var left = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_LEFT_SIDE)) > -1
	var right = tilemap.get_cell_source_id(tilemap.get_neighbor_cell(cell_position,TileSet.CELL_NEIGHBOR_RIGHT_SIDE)) > -1

	# raycast can give corners. so have to invalidate when all direct neighbors are blank
	if not (top or bottom or left or right):
		return false
	
	var new_position = grid_position
	var orientation = GameManager.ORIENTATION_VECTORS[determine_tile_face(raycast_normal)]

	# keep the tilemap aligned axis constant, and other axis to move freely
	# i.e. if on wall, keep x constant, and move y
	if orientation.x != 0:
		new_position.y = raycast_position.y
	if orientation.y != 0:
		new_position.x = raycast_position.x

	
	# clip the position to tilemap edges, so no overhanging portals
	# orientation is opposite of raycast normal
	match orientation:
		# on left wall
		Vector2.RIGHT:
			if bottom or not bottom_left:
				new_position.y = min(grid_position.y-portal_size_overhang, raycast_position.y)
		
			if top or not top_left:
				new_position.y = max(grid_position.y+portal_size_overhang, raycast_position.y)
		# on right wall
		Vector2.LEFT:
			if bottom or not bottom_right:
				new_position.y = min(grid_position.y-portal_size_overhang, raycast_position.y)
			
			if top or not top_right:
				new_position.y = max(grid_position.y+portal_size_overhang, raycast_position.y)
		# on floor
		Vector2.UP:
			if left or not bottom_left:
				new_position.x = max(grid_position.x+portal_size_overhang, raycast_position.x)
			
			if right or not bottom_right:
				new_position.x = min(grid_position.x-portal_size_overhang, raycast_position.x)
		# on ceiling
		Vector2.DOWN:
			if left or not top_left:
				new_position.x = max(grid_position.x+portal_size_overhang, raycast_position.x)
			
			if right or not top_right:
				new_position.x = min(grid_position.x-portal_size_overhang, raycast_position.x)
		_:
			print("apparently not an orientation? ", orientation)

	# this is some cursed code, but it works
	# definitely can be done better, I'm just lazy
	# TODO: duplicate area2d, run the check, if it overlaps with the other portal, try to nudge it, then place it
	# if orange portal overlaps with blue portal, try to place it at a different position
	match portal:
		"orange":
			
			orange_portal.visible = false
			place_orange(new_position, orientation, grid_position)

			# godot position updates can be delayed, so we need to wait a couple frames
			# this will add slight delay to the portal placement, but it is necessary
			await get_tree().process_frame
			await get_tree().process_frame
			if orange_portal.overlaps_area(blue_portal):
				# stop infinity! and beyond!
				if recursive:
					return false
				var result = await nudge_portal("orange", orientation, raycast_normal)
				if not result:
					print("Failed to place orange portal, no valid position found")
					return false
			orange_portal.visible = true
		"blue":
			blue_portal.visible = false
			place_blue(new_position, orientation, grid_position)

			# godot position updates can be delayed, so we need to wait a couple frames
			# this will add slight delay to the portal placement, but it is necessary
			await get_tree().process_frame
			await get_tree().process_frame
			if blue_portal.overlaps_area(orange_portal):
				# stop infinity! and beyond!
				if recursive:
					return false
				var result = await nudge_portal("blue", orientation, raycast_normal)
				if not result:
					print("Failed to place blue portal, no valid position found")
					return false
			blue_portal.visible = true
		_:
			print("Unknown portal type: ", portal)
			return false
	
	make_surrounding_collisions(grid_position, orange_portal if portal == "orange" else blue_portal)

	return true

func nudge_portal(portal: String, orientation: Vector2, raycast_normal: Vector2) -> bool:
	print("attempting to place ", portal, " portal at a different position")

	var portal1 = blue_portal if portal == "blue" else orange_portal
	var portal2 = blue_portal if portal1 == orange_portal else orange_portal

	var portal_relative_direction: Vector2 = -sign(portal2.global_position - portal1.global_position)
	var max_attempts = 5
	var attempt = 0
	var n = portal2.global_position
	var shift = Vector2.ZERO
	match orientation:
		Vector2.LEFT, Vector2.RIGHT:
			shift.y = 8 * portal_relative_direction.y
			n += shift
		Vector2.UP, Vector2.DOWN:
			shift.x = 8 * portal_relative_direction.x
			n += shift
	# try to place the portal at a different position
	# if it overlaps with the orange portal, try to shift it
	# in the direction of the orange portal
	# if it still overlaps, try to shift it again
	# up to max_attempts times
	# if it still overlaps, return false
	var placed = false
	while attempt < max_attempts and not placed:
		var res = await place_portal(portal, n, raycast_normal, true)
		if res:
			placed = true
		else:
			attempt += 1
			n += shift
	return placed

func place_orange(position: Vector2, orientation: Vector2, grid_position: Vector2):
	orange_portal.global_position = position
	var rot = orientation.angle()
	orange_portal.rotation = rot
	orange_portal.global_position += Vector2(-16.0,0.0).rotated(rot)
	orange_portal.get_node_or_null("grid_aligned").global_position = grid_position

	orange_portal.orientation = orientation



func place_blue(position: Vector2, orientation: Vector2, grid_position: Vector2):
	blue_portal.global_position = position
	var rot = orientation.angle()
	blue_portal.rotation = rot
	blue_portal.global_position += Vector2(-16.0,0.0).rotated(rot)
	blue_portal.get_node_or_null("grid_aligned").global_position = grid_position

	blue_portal.orientation = orientation


func make_surrounding_collisions(grid_position: Vector2, portal: GenericPortal):
	portal.clear_collisions()

	var tilemap: TileMapLayer = %tilemaps/foreground/foreground_0
	var cell_position = tilemap.local_to_map(tilemap.to_local(grid_position))
	
	if tilemap.get_cell_source_id(cell_position) > -1:
		return false
	
	# Find all collidable tiles in 6x6 area around portal
	for x in range(-3, 3):
		for y in range(-3, 3):
			if x == 0 and y == 0:
				continue
				
			var neighbor_cell = cell_position + Vector2i(x, y)
			if tilemap.get_cell_source_id(neighbor_cell) == -1:
				continue
				
			var tile_world_pos = tilemap.to_global(tilemap.map_to_local(neighbor_cell))
			var difference = tile_world_pos - portal.global_position
			
			# Skip tiles too close to portal (cutout area)
			if abs(difference.x) < 48 and abs(difference.y) < 48:
				continue
				
			portal.add_collision(tile_world_pos)
		


func determine_tile_face(normal: Vector2) -> GameManager.Orientation:
	var Orientation = GameManager.Orientation
	if normal == Vector2.LEFT:
		return Orientation.LEFT
	elif normal == Vector2.RIGHT:
		return Orientation.RIGHT
	elif normal == Vector2.UP:
		return Orientation.UP
	elif normal == Vector2.DOWN:
		return Orientation.DOWN
	else:
		return Orientation.DOWN  # Default orientation if no match found

func _process(delta: float) -> void:
	# update the portal travellers
	for traveller in portal_travellers:
		var object: AnimatedSprite2D = traveller[0]
		var original_object: AnimatedSprite2D = traveller[1]
		var portal = traveller[2]
		var other_portal = traveller[3]
		if original_object.global_position.distance_to(portal.global_position) > 1000:
			print("removing traveller: ", object)
			object.queue_free()
			portal_travellers.erase(traveller)
		
		var distance_to_portal = original_object.global_position - portal.global_position
		var relative_rotation = original_object.global_rotation - portal.global_rotation

		# move the traveller to the mirrored side of the other portal, accounting for rotation
		var local_offset = (original_object.global_position - portal.global_position + Vector2(16,0)).rotated(-portal.global_rotation)
		# Mirror the offset across the portal's local axis (Y axis for 2D portals)
		local_offset.x = -local_offset.x + 32
		var rotated_offset = local_offset.rotated(other_portal.global_rotation)
		object.global_position = other_portal.global_position + rotated_offset

		object.global_rotation = other_portal.global_rotation + relative_rotation + PI
		object.sprite_frames = original_object.sprite_frames
		object.frame = original_object.frame
		object.animation = original_object.animation
		object.flip_h = original_object.flip_h


func _generic_portal_body_entered(body: Node2D, portal: GenericPortal, other_portal: GenericPortal) -> void:
	if not body.is_in_group("portal_traveller"):
		return
	var p: Player = body
	# Disable collision layer 1 for the player when entering the portal
	p.collision_layer &= ~1
	p.collision_mask &= ~1
	var children = body.get_children()
	for child in children:
		if child is PortalTravellerHelper:
			print("traveller found: ", child)
			var original = child.get_sprite()
			var traveller = original.duplicate()
			traveller.set_script(null)  # remove script to prevent duplicate script instances
			print("traveller: ", traveller)
			other_portal.travellers_container.add_child(traveller)
			# other_portal.add_child(traveller)
			portal_travellers.append([traveller, original, portal, other_portal])
			traveller.global_position = other_portal.global_position
			traveller.global_rotation = other_portal.global_rotation

func _generic_portal_body_exited(body: Node2D, portal: GenericPortal) -> void:
	if not body.is_in_group("portal_traveller"):
		return
	
	var p: Player = body
	# Re-enable collision layer 1 for the player when exiting the portal
	p.collision_layer |= 1
	p.collision_mask |= 1
	
	var children = body.get_children()
	for child in children:
		if child is PortalTravellerHelper:
			print("traveller exited: ", child)
			var original = child.get_sprite()
			for traveller in portal_travellers:
				if traveller[1] == original:
					traveller[0].queue_free()
					portal.travellers_container.remove_child(traveller[0])
					portal_travellers.erase(traveller)
					break 

func _remove_scripts_recursive(node: Node) -> void:
	if node is Node2D and node.get_script() != null:
		node.set_script(null)
	for child in node.get_children():
		_remove_scripts_recursive(child)

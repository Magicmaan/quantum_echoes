extends CanvasGroup

@onready var orange_portal: Area2D = $orange_portal
@onready var blue_portal: Area2D = $blue_portal 
@onready var portal_size: float = orange_portal.get_node("CollisionShape2D").shape.size.y
@onready var portal_size_overhang: float = (portal_size - 16.0) / 2.0

func place_portal(portal: String, raycast_position: Vector2, raycast_normal: Vector2, recursive: bool = false) -> bool:
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
	orange_portal.global_position += Vector2(-6.0,0.0).rotated(rot)
	orange_portal.get_node_or_null("grid_aligned").global_position = grid_position-Vector2(8 * -orientation.x, 8 * -orientation.y)


func place_blue(position: Vector2, orientation: Vector2, grid_position: Vector2):
	blue_portal.global_position = position
	var rot = orientation.angle()
	blue_portal.rotation = rot
	blue_portal.global_position += Vector2(-6.0,0.0).rotated(rot)
	blue_portal.get_node_or_null("grid_aligned").global_position = grid_position-Vector2(8 * -orientation.x, 8 * -orientation.y)


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

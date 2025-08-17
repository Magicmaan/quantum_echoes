extends RayCast2D

# variable for correction amount to apply to position
# raycast has issue with tilemaps and rounding, where if it hits top side or left side, it gets embedded
# so apply small offset to get nearest empty tile
@export var correction_amount: float = 0.1

# returns the tilemap local coordinates for cell if collided, else returns Vector2(0,0)
func get_collision_tilemap() -> Vector2:
# ensure is colliding
	if !is_colliding():
		print("not colliding")
		return Vector2.ZERO
#	ensure is tilemap
	if get_collider() != TileMapLayer:
		return Vector2.ZERO
	
	var collision_point = get_collision_point()
	var collision_normal = get_collision_normal()
	
#	convert hit point to tilemap cell coordinates and return it.
	var tilemap: TileMapLayer = get_collider() as TileMapLayer
	var local_pos := tilemap.to_local(collision_point + collision_normal * correction_amount)
	var cell := tilemap.local_to_map(local_pos)
	var grid_aligned_pos := tilemap.map_to_local(cell)
	print("reutnring ", cell)
	return cell
	

func get_collided_cell() -> Variant:
	if is_colliding():
		var collision_point = get_collision_point()
		var collision_normal = get_collision_normal()
		var collider = get_collider()

		if collider is TileMapLayer:
			var tilemap: TileMapLayer = collider
			var adjusted_pos = collision_point + collision_normal * 0.1
			var local_pos = tilemap.to_local(adjusted_pos)
			var cell: Vector2i = tilemap.local_to_map(local_pos)
			return cell
	return null

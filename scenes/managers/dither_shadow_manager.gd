@tool
extends Node2D


@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var texture_rect: TextureRect = $TextureRect

var tilemaps: Array[TileMapLayer] = []
var lights: Array[Light2D] = []
#
func _ready() -> void:
	if Engine.is_editor_hint():
		await get_tree().process_frame
		generate_dither_shadows()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		render_shadows()

func _enter_tree() -> void:
	await get_tree().process_frame
	generate_dither_shadows()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	render_shadows()

func _process(_delta):
	if Engine.is_editor_hint():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_container.queue_redraw()
		render_shadows()
		# generate_dither_shadows()
	else:
		viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
		
		#viewport_container.queue_free()

func generate_dither_shadows() -> void:
	print("Searching for tilemaps in the scene...")
	_get_tilemaps()
	if tilemaps.size() == 0:
		print("No tilemaps found in the scene.")
		print("disable dither shadows")
		print("Make sure you have tilemaps in the scene and they are in the 'tilemap_dither_shadows' group.")
		return
	_add_tilemaps()

	_get_lights()
	if lights.size() == 0:
		print("No lights found in the scene.")
		print("Make sure you have lights in the scene and they are in the 'light_dither_shadows' group.")
		return
	_add_lights()

	

func render_shadows() -> void:
	viewport_container.visible = true
	viewport_container.visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	var tex = viewport.get_texture().get_image()
	var static_texture = ImageTexture.create_from_image(tex)
	
	texture_rect.texture = static_texture


func _add_tilemaps() -> void:
	var rect_size = Vector2(256, 256)
	for tilemap in tilemaps:
		# occlusion is needed for shadows on the lightmap
		if !tilemap.occlusion_enabled:
			print("Enabling occlusion for tilemap: ", tilemap.name)
			tilemap.occlusion_enabled = true
		
#		set lightmask and visibility to layer 10 only (dither shadows layer)
		tilemap.light_mask = 1 << 0
		tilemap.visibility_layer = 1 << 0
		
		# calculate size of the tilemap for use by the imageRect background
		# needed for the shadows to appear correctly
		var tilemap_rect = tilemap.get_used_rect()
		var pixel_size = Vector2(tilemap_rect.size.x * tilemap.tile_set.tile_size.x, 
						  tilemap_rect.size.y * tilemap.tile_set.tile_size.y)

		if rect_size.x < pixel_size.x:
			rect_size.x = pixel_size.x
		if rect_size.y < pixel_size.y:
			rect_size.y = pixel_size.y

#		add tilemap to the viewport
		print("adding tilemap", tilemap.name, " to the dither viewport")
		viewport.add_child(tilemap)
	


func _get_tilemaps() -> void:
	var maps = get_tree().get_nodes_in_group("tilemap_dither_shadows")
	for map in maps:
		if map is TileMapLayer:
			tilemaps.append(map.duplicate())
	print("Tilemaps found: ", tilemaps.size())

func _add_lights() -> void:
	for light in lights:
		if light.shadow_enabled == false:
			continue
		
		
		light.visible = true
		# set light mask and visibility to layer 10 only (dither shadows layer)
		light.range_item_cull_mask = 1 << 0
		light.shadow_item_cull_mask = 1 << 0
		light.visibility_layer = 1 << 0
		light.light_mask = 1 << 0 
		
		light.shadow_enabled = true
		light.blend_mode = Light2D.BLEND_MODE_SUB
		light.energy = 16.0
		
		print("adding light ", light.name, " to the dither viewport")
		viewport.add_child(light)


func _get_lights() -> void:
	var light_list = get_tree().get_nodes_in_group("light_dither_shadows")
	for light in light_list:
		if light is Light2D:
			lights.append(light.duplicate())
	print("Lights found: ", lights.size())

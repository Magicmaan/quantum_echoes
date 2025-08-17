extends Node2D


func _process(delta):
	queue_redraw()

func _draw():
	var portal_gun = get_parent()  # Assuming Portal_Gun is RayMark’s parent
	if portal_gun:
		var portal_pos_local = to_local(portal_gun.global_position)
		var own_origin = Vector2.ZERO
		draw_line(own_origin, portal_pos_local, Color(1,0,0), -1)

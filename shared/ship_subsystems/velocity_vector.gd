extends Node2D


func _process(_delta):
	update()

func _draw():
	var ship = get_parent().get_parent().get_parent().get_parent()
	var ship_velocity_transformed = (ship.ship_velocity/50).rotated(-global_rotation)
	draw_circle(ship_velocity_transformed,0.5,Color.white)
	draw_line(Vector2.ZERO,ship_velocity_transformed,Color.white,1.0,true)
	draw_polygon(
		PoolVector2Array([Vector2(-1,0),Vector2(1,0),Vector2(0,-1)]),
		PoolColorArray([Color.white])
		)

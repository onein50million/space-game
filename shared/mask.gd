extends Node2D



const THICKNESS = 1.0 #how much of the object will be shown
var rotate = 0.0
const ROTATE_INCREASE = 0.1
var draw_rays = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().server_side or not get_parent().is_local:
		set_process(false)
		set_physics_process(false)
		visible = false


func _process(delta):
	update()

func _draw():
	if $"../..".outside_view:
		return

	var blockers = []
	for ship in get_parent().get_parent().get_parent().ship_list.values():
		for blocker in ship.ship_shape_blockers:
			var added_blocker = []
			for vertex in blocker:
				var vertex_global_position = ship.global_position + vertex.rotated(ship.global_rotation)
				added_blocker.append(vertex_global_position)
			blockers.append(added_blocker)

	for blocker in blockers:
		var vertices = blocker
		for i in range(0,vertices.size()):
			var ray_distance = max(
				get_viewport_rect().size.x,
				get_viewport_rect().size.y)
			ray_distance = max(ray_distance, global_position.distance_to(vertices[i-1]))
			ray_distance = max(ray_distance, global_position.distance_to(vertices[i]))
			ray_distance *= 2.5 #for good measure, don't want any weird triangles
			var previous_ray_angle = fposmod(global_position.angle_to_point(vertices[i-1]) - global_rotation + PI,TAU)
			var ray_angle = fposmod(global_position.angle_to_point(vertices[i]) - global_rotation + PI,TAU)

			var colors = PoolColorArray([Color.black])
			var points = PoolVector2Array([
				global_transform.xform_inv(vertices[i-1]),
				global_transform.xform_inv(vertices[i]),
				Vector2(ray_distance,0.0).rotated(ray_angle),
				((global_transform.xform_inv(vertices[i-1]).normalized() + global_transform.xform_inv(vertices[i]).normalized())/2.0).normalized() * ray_distance,
				Vector2(ray_distance,0.0).rotated(previous_ray_angle)
			])

			draw_polygon(points,colors)
			if draw_rays:
				draw_line(Vector2(0.0,0.0), global_transform.xform_inv(vertices[i]) ,Color.red)
				draw_line(global_transform.xform_inv(vertices[i-1]),global_transform.xform_inv(vertices[i]),Color.green)
				draw_line(global_transform.xform_inv(vertices[i]), Vector2(ray_distance,0).rotated(ray_angle),Color.blue)





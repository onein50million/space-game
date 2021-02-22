extends Node2D


const NUM_RAYS = 1000
var ray_results = []

var draw_rays = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().server_side:
		set_process(false)
		set_physics_process(false)
	for i in range(0, NUM_RAYS):
		ray_results.append(10.0)

func _process(delta):
	update()

func _physics_process(delta):
	var ray_distance = max(get_viewport_rect().size.x, get_viewport_rect().size.x)
	var space_state = get_world_2d().direct_space_state
	for i in range(0,NUM_RAYS):
		var angle = TAU*(float(i)/float(NUM_RAYS))
		var result = space_state.intersect_ray(
				get_parent().global_position, 
				global_position + Vector2(ray_distance,0.0).rotated(angle),
				[self], 
				0b1000,true,true)
		if result.size() > 0:
			ray_results[i] = get_parent().global_position.distance_to(result.position)
		else:
			ray_results[i] = ray_distance

func _draw():
	for i in range(0,NUM_RAYS):
		var previous_angle = TAU*(float(i-1)/float(NUM_RAYS))
		var angle = TAU*(float(i)/float(NUM_RAYS))
		if draw_rays:
			draw_line(Vector2(0.0,0.0), Vector2(ray_results[i],0.0).rotated(angle),Color.red)
		var colors = PoolColorArray([Color.black])
		var points = PoolVector2Array([
			Vector2(ray_results[i-1],0.0).rotated(previous_angle),
			Vector2(ray_results[i],0.0).rotated(angle),
			Vector2(1000.0,0.0).rotated(angle),
			Vector2(1000.0,0.0).rotated(previous_angle),
		])
		draw_polygon(points,colors)
#	for blocker in get_tree().get_nodes_in_group("vision_block"):
#		for vertex in blocker.get_polygon():
#			#triangle made from abc
#			var a = 0.0
#			var b = 0.0
#			var c = 0.0
#			draw_circle(get_global_transform().xform_inv(blocker.global_position + vertex.rotated(blocker.global_rotation)),10.0,Color.black)
#	print(get_viewport_rect())


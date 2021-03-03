extends RigidBody2D

var max_health = 100.0
var health = max_health
var misc_id
var object_type = "alien"
var server_side = false

func _ready():
	pass

func _process(delta):
	if server_side:
		if health <= 0.0:
			die()

func _physics_process(delta):
	if server_side:
		var server = get_parent()
		var closest_ship
		var minimum_distance = INF
		for ship in server.ship_list.values():
			var distance = global_position.distance_to(ship.global_position)
			if distance < minimum_distance:
				minimum_distance = distance
				closest_ship = ship
		if closest_ship:
			look_at(closest_ship.global_position)
			add_central_force(Vector2.RIGHT.rotated(global_rotation))

func die():
	if server_side:
		var server = get_parent()
		server.delete_misc(misc_id)
	queue_free()

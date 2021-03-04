extends RigidBody2D

var max_health = 100.0
var health = max_health
var misc_id
var object_type = "alien"
var server_side = false

var attached = false

var send_data = {
	"attached" : false
}

var time = 0
const DAMAGE_RATE = 10.0

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	time += rng.randf()
	

func _process(_delta):
	if attached and not $gnaw_sound.playing:
		$gnaw_sound.playing = true
	if server_side:
		send_data.attached = attached
		if health <= 0.0:
			die()
	else:
		attached = send_data.attached
func _physics_process(delta):
	time += delta

	if server_side:
		var server = get_tree().get_root().get_node("server")
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
		rotate(sin(time*10.0)/100.0)
		if attached:
			get_parent().health -= DAMAGE_RATE*delta
func attach(body):
	attached = true
	var saved_position = global_position
	if get_parent() != body:
		collision_mask = 0b110100
		collision_layer = 0b100000
		body.attached.append(self)
		set_mode(MODE_KINEMATIC)
		get_parent().remove_child(self)
		body.add_child(self)
		global_position = saved_position


func die():
	if server_side:
		var server = get_tree().get_root().get_node("server")
		server.delete_misc(misc_id)
	queue_free()

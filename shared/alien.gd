extends RigidBody2D

onready var guts = [
	preload("res://shared/alien/guts0.tscn"),
	preload("res://shared/alien/guts1.tscn"),
	preload("res://shared/alien/guts2.tscn"),
	preload("res://shared/alien/guts3.tscn")
]
onready var splat_sound_scene = preload("res://assets/alien/guts/splat_sound.tscn")
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
		spawn_guts()
	var new_sound = splat_sound_scene.instance()
	get_parent().add_child(new_sound)
	new_sound.global_position = global_position
	queue_free()


func spawn_guts():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = 0
	for gut_scene in guts:
		var server = get_tree().get_root().get_node("server")
		var new_gut = server.spawn_body(gut_scene,false,false,global_position)
		new_gut.send_data.index = index

		new_gut.global_rotation = (global_rotation + PI/2.0) * rng.randf_range(0.9,1.1)
		new_gut.linear_velocity = linear_velocity * rng.randf_range(0.9,1.1)
		new_gut.angular_velocity = angular_velocity + rng.randf_range(-10.0,10.0)
		new_gut.mass = mass *0.25
		new_gut.server_side = server_side
		index += 1

		

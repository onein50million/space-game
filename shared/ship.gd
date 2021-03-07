extends RigidBody2D

onready var explosion_scene = load("res://shared/explosion.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var server_side = false
var ship_velocity = Vector2(0.0,0.0)
var outside_view = false

var temporary = false

var ship_shape = PoolVector2Array()
var ship_shape_blockers = []
var systems = []

var attached = []

var ship_type = "test_ship_two.json"

var max_health = 10000.0
var health = max_health

var dying = false
var die_timer_start = 3.0
var die_timer = die_timer_start
const SPEED = 100.0
const ROTATION = 10000.0

var inputs = {
	"forward" : false,
	"backward" : false,
	"left" : false,
	"right" : false,
}

func damage(damage):
	var damage_dealt = min(health,damage)
	health -= damage_dealt
	return damage_dealt

# Called when the node enters the scene tree for the first time.
func _ready():
	contact_monitor = true
	contacts_reported = 32
	yield(get_tree(), "idle_frame")
	var file = File.new()
	print(ship_type)
	print("file open: %s" % file.open("res://ships/%s" % ship_type,file.READ))
	var parsed = parse_json(file.get_as_text())
	file.close()
	var reversed_points = parsed.points.duplicate(true)
	reversed_points.invert()
	for i in range(0,reversed_points.size()):
		reversed_points[i][0] *= -1.0
#		if reversed_points[i][0] == 0:
#			reversed_points.remove(i)
	
	var points = parsed.points + reversed_points


	for i in range(0,points.size()):
		var new_area = Area2D.new()
		var new_outside_segment = Line2D.new()
		$outside_layer.add_child(new_outside_segment)
		var shift = -1
		if i >= parsed.points.size():
			shift = 0
		var blocker = false
		match points[i+shift][2]:
			"wall":
				new_area.collision_layer=0b11100
				new_outside_segment.default_color = Color.gray
				blocker = true
			"window":
				new_area.collision_layer = 0b00100
				new_outside_segment.default_color = Color.lightblue * Color(1,1,1,0.3)
			"door":
				new_area.collision_layer = 0b00100
				new_outside_segment.default_color = Color.lightgreen * Color(1,1,1,0.3)
			"_":
				print("unknown wall type")
				new_area.collision_layer = 0b1100
				new_outside_segment.default_color = Color.pink
		add_child(new_area)
		new_area.add_to_group("ship_wall")
		
		var new_collision_shape = CollisionShape2D.new()
		new_area.add_child(new_collision_shape)
		var new_segment = SegmentShape2D.new()
		var a = Vector2(points[i-1][0],points[i-1][1])
		var b = Vector2(points[i][0],points[i][1])
		new_segment.a = a
		new_segment.b = b
		
		if blocker:
			ship_shape_blockers.append([a,b,points[i+shift][2]])
		
		new_outside_segment.points = PoolVector2Array([a,b])
		ship_shape.append(Vector2(points[i][0],points[i][1]))
		new_collision_shape.shape = new_segment
	
	#interior walls
	var interior_walls = parsed.interior_walls
	var mirrored_walls = interior_walls.duplicate(true)
	for mirrored_wall in mirrored_walls:
		mirrored_wall.start[0]*=-1.0
		mirrored_wall.end[0]*=-1.0
	interior_walls += mirrored_walls
	for interior_wall in interior_walls:
		var a = Vector2(interior_wall.start[0],interior_wall.start[1])
		var b = Vector2(interior_wall.end[0],interior_wall.end[1])
		
		var new_area = Area2D.new()
		var new_interior_wall = Line2D.new()
		new_interior_wall.width = 2.0
		var blocker = false
		match interior_wall.type:
			"wall":
				blocker = true
				new_area.collision_layer=0b11100
				new_interior_wall.default_color = Color.darkgray
			"window":
				blocker = false
				new_area.collision_layer=0b00100
				new_interior_wall.default_color = Color.darkblue*Color(1,1,1,0.3)
			"door":
				blocker = true
				new_area.collision_layer=0b11100
				new_interior_wall.default_color = Color.darkgreen*Color(1,1,1,0.3)
		add_child(new_area)
		var new_collision_shape = CollisionShape2D.new()
		new_area.add_child(new_collision_shape)
		var new_segment = SegmentShape2D.new()
		new_segment.a = a
		new_segment.b = b
		new_collision_shape.shape = new_segment
		new_area.add_to_group("ship_wall")
		add_child(new_interior_wall)
		new_interior_wall.points = PoolVector2Array([a,b])
		
		if blocker:
			ship_shape_blockers.append([a,b,interior_wall.type])
		
	$collision_poly.set_polygon(ship_shape)
	$poly.set_polygon(ship_shape)
	$"outside_layer/poly".set_polygon(ship_shape)
	


	for system in parsed.systems:
		var new_system = null
		var parent = self
		match system.type:
			"captain":	
				new_system = load("res://shared/ship_subsystems/captain.tscn").instance()
			"map":
				new_system = load("res://shared/ship_subsystems/map/map.tscn").instance()
			"weapons":
				new_system = load("res://shared/ship_subsystems/weapons.tscn").instance()
			"turret":
				new_system = load("res://shared/ship_subsystems/turret.tscn").instance()
				parent = $outside_layer
				new_system.RANGE = system.weapon_range
				new_system.DAMAGE = system.damage
				new_system.FIRE_RATE = system.fire_rate
			"communications":
				new_system = load("res://shared/ship_subsystems/communications.tscn").instance()
			"capacitor":
				new_system = load("res://shared/ship_subsystems/capacitor/capacitor.tscn").instance()
			"shield":
				new_system = load("res://shared/ship_subsystems/shield/shield.tscn").instance()
				new_system.shield_diameter = system.diameter
				parent = $outside_layer
			_:
				print("unknown system type")
		if new_system != null:
			systems.append(new_system)
			parent.add_child(new_system)
			new_system.set_position(Vector2(system.position[0], system.position[1]))
			new_system.server_side = server_side
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if outside_view:
		$outside_layer.z_index = 1024
	else:
		$outside_layer.z_index = -1024
	if server_side:
		ship_velocity = get_linear_velocity()
	
	for blocker in ship_shape_blockers:
		if blocker[2] == "door":
			blocker[0] = blocker[0] + Vector2(10,0)
			blocker[1] = blocker[1] + Vector2(10,0)
	$health.set_text("Integrity: %.2f%%" % ((health/max_health)*100))
func _physics_process(delta):

	if health <= 0.0 and not dying:
		die()
	if dying:
		die_timer -= delta
		if die_timer <= 0.0:
			dying = false
			if server_side:
				respawn()
			die_timer = die_timer_start
	if inputs.forward:
#		position += Vector2.UP.rotated(global_rotation)* SPEED
		if server_side:
			apply_central_impulse(Vector2.UP.rotated(global_rotation)* SPEED * delta)
	elif inputs.backward:
#		position += Vector2.DOWN.rotated(global_rotation) * SPEED
		if server_side:
			apply_central_impulse(Vector2.DOWN.rotated(global_rotation)* SPEED * delta)
	if inputs.left:
		if server_side:
			apply_torque_impulse(-ROTATION * delta)
	if inputs.right:
		if server_side:
			apply_torque_impulse(ROTATION * delta)
	if not true in inputs.values():
		pass

func die():
	var new_explosion = explosion_scene.instance()
	get_parent().add_child(new_explosion)
	new_explosion.global_position = global_position
	dying = true

func respawn():
	for attached_body in attached:
		if attached_body:
			attached_body.die()
			
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var new_position = Vector2(rng.randfn(Globals.GAME_AREA,0.1),0).rotated(rng.randf_range(0,TAU))
	while not get_parent().is_position_clear(new_position):
		new_position = Vector2(rng.randfn(Globals.GAME_AREA,0.1),0).rotated(rng.randf_range(0,TAU))
	global_position = new_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	health = max_health


func _on_ship_body_entered(body):
	if server_side:
		if "object_type" in body:
			if body.object_type == "alien":
				body.call_deferred("attach",self)

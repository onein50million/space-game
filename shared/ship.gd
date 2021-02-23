extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var server_side = false
var ship_velocity = Vector2(0.0,0.0)


const SPEED = 100.0
const ROTATION = 10000.0

var inputs = {
	"forward" : false,
	"backward" : false,
	"left" : false,
	"right" : false,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	print("file open: %s" % file.open("res://ships/test_ship_two.json",file.READ))
	var parsed = parse_json(file.get_as_text())
	file.close()
	print(parsed)
	var reversed_points = parsed.points.duplicate(true)
	reversed_points.invert()
	for i in range(0,reversed_points.size()):
		reversed_points[i][0] *= -1.0
#		if reversed_points[i][0] == 0:
#			reversed_points.remove(i)
		
	var points = parsed.points + reversed_points
	var ship_shape = PoolVector2Array()

	for i in range(0,points.size()):
		print(points[i])
		var new_area = Area2D.new()
		var shift = -1
		if i >= parsed.points.size():
			shift = 0
		match points[i+shift][2]:
			"wall":
				new_area.collision_layer=0b1100
			"window":
				new_area.collision_layer = 0b0100
			"_":
				print("unknown wall type")
				new_area.collision_layer = 0b1100
		add_child(new_area)
		var new_collision_shape = CollisionShape2D.new()
		new_area.add_child(new_collision_shape)
		var new_segment = SegmentShape2D.new()
		new_segment.a = Vector2(points[i-1][0],points[i-1][1])
		new_segment.b = Vector2(points[i][0],points[i][1])
		ship_shape.append(Vector2(points[i][0],points[i][1]))
		new_collision_shape.shape = new_segment

	$collision_poly.set_polygon(ship_shape)
	$poly.set_polygon(ship_shape)
	for system in parsed.systems:
		match system.type:
			"captain":	
				var new_captain = load("res://client/ship_subsystems/captain.tscn").instance()
				add_child(new_captain)
				new_captain.set_position(Vector2(system.position[0], system.position[1]))
			"map":
				var new_map = load("res://client/ship_subsystems/map.tscn").instance()
				add_child(new_map)
				new_map.set_position(Vector2(system.position[0],system.position[1]))
			"weapons":
				var new_weapons = load("res://client/ship_subsystems/weapons.tscn").instance()
				add_child(new_weapons)
				new_weapons.set_position(Vector2(system.position[0],system.position[1]))
			"_":
				print("unknown system type")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if server_side:
		ship_velocity = get_linear_velocity()
	$velocity.set_text("Vel: %.f" % ship_velocity.length())
	$position.set_text("X: %.f\nY: %.f" % [get_position().x, get_position().y])
func _physics_process(delta):

	if inputs.forward:
#		position += Vector2.UP.rotated(global_rotation)* SPEED
		if server_side:
			apply_central_impulse(Vector2.UP.rotated(global_rotation)* SPEED * delta)
		$lengine.set_emitting(true)
		$rengine.set_emitting(true)	
	elif inputs.backward:
#		position += Vector2.DOWN.rotated(global_rotation) * SPEED
		if server_side:
			apply_central_impulse(Vector2.DOWN.rotated(global_rotation)* SPEED * delta)
	if inputs.left:
		if server_side:
			apply_torque_impulse(-ROTATION * delta)
		$rengine.set_emitting(true)
	if inputs.right:
		if server_side:
			apply_torque_impulse(ROTATION * delta)
		$lengine.set_emitting(true)
	if not true in inputs.values():
		$lengine.set_emitting(false)
		$rengine.set_emitting(false)	

extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var server_side = false
var ship_velocity = Vector2(0.0,0.0)
var outside_view = false
var ship_shape = PoolVector2Array()
var ship_shape_blockers = []
var systems = []


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
				new_area.collision_layer=0b1100
				new_outside_segment.default_color = Color.gray
				blocker = true
			"window":
				new_area.collision_layer = 0b0100
				new_outside_segment.default_color = Color.lightblue * Color(1,1,1,0.3)
			"_":
				print("unknown wall type")
				new_area.collision_layer = 0b1100
				new_outside_segment.default_color = Color.pink
		add_child(new_area)
		var new_collision_shape = CollisionShape2D.new()
		new_area.add_child(new_collision_shape)
		var new_segment = SegmentShape2D.new()
		var a = Vector2(points[i-1][0],points[i-1][1])
		var b = Vector2(points[i][0],points[i][1])
		new_segment.a = a
		new_segment.b = b
		
		if blocker:
			ship_shape_blockers.append([a,b])
		
		new_outside_segment.points = PoolVector2Array([a,b])
		ship_shape.append(Vector2(points[i][0],points[i][1]))
		new_collision_shape.shape = new_segment

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
				new_system = load("res://shared/ship_subsystems/map.tscn").instance()
			"weapons":
				new_system = load("res://shared/ship_subsystems/weapons.tscn").instance()
			"turret":
				new_system = load("res://shared/ship_subsystems/turret.tscn").instance()
				parent = $outside_layer
			"communications":
				new_system = load("res://shared/ship_subsystems/communications.tscn").instance()
			"_":
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
		
	$velocity.set_text("Vel: %.f" % ship_velocity.length())
	$position.set_text("X: %.f\nY: %.f" % [get_position().x, get_position().y])
func _physics_process(delta):

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

extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var server_side = false
var ship_velocity = Vector2(0.0,0.0)

const SPEED = 100.0
const ROTATION = 10000.0
# Called when the node enters the scene tree for the first time.
func _ready():
	$collision_poly.set_polygon($poly.get_polygon())
	$ship_wall/player_collision_poly.set_polygon($poly.get_polygon())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if server_side:
		ship_velocity = get_linear_velocity()
	$velocity.set_text("Vel: %.f" % ship_velocity.length())
	$position.set_text("X: %.f\nY: %.f" % [get_position().x, get_position().y])
func _physics_process(delta):

	if $up.get_overlapping_areas().size() > 0:
#		position += Vector2.UP.rotated(global_rotation)* SPEED
		if server_side:
			apply_central_impulse(Vector2.UP.rotated(global_rotation)* SPEED * delta)
		$up/Polygon2D.set_color(Color.green)
		$lengine.set_emitting(true)
		$rengine.set_emitting(true)	
	elif $down.get_overlapping_areas().size() > 0:
#		position += Vector2.DOWN.rotated(global_rotation) * SPEED
		if server_side:
			apply_central_impulse(Vector2.DOWN.rotated(global_rotation)* SPEED * delta)
		$down/Polygon2D.set_color(Color.green)
	elif $left.get_overlapping_areas().size() > 0:
		if server_side:
			apply_torque_impulse(-ROTATION * delta)
		$left/Polygon2D.set_color(Color.green)
		$rengine.set_emitting(true)
	elif $right.get_overlapping_areas().size() > 0:
		if server_side:
			apply_torque_impulse(ROTATION * delta)
		$right/Polygon2D.set_color(Color.green)
		$lengine.set_emitting(true)
	else:
		$up/Polygon2D.set_color(Color.white)
		$down/Polygon2D.set_color(Color.white)
		$left/Polygon2D.set_color(Color.white)
		$right/Polygon2D.set_color(Color.white)
		$lengine.set_emitting(false)
		$rengine.set_emitting(false)	

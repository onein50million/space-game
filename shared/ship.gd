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
	$collision_poly.set_polygon($poly.get_polygon())
	$ship_wall/player_collision_poly.set_polygon($poly.get_polygon())


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
	if true in inputs.values():
		$lengine.set_emitting(false)
		$rengine.set_emitting(false)	

extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var object_type = "asteroid"
var misc_id
var server_side = false

var send_data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	$collision_poly.set_polygon($poly.get_polygon())


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

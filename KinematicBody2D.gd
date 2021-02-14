extends RigidBody2D


#Just a test script


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	var input_vector : Vector2 = Vector2.ZERO
	if Input.is_action_pressed("up"):
		input_vector += Vector2.UP
	if Input.is_action_pressed("down"):
		input_vector += Vector2.DOWN
	if Input.is_action_pressed("left"):
		input_vector += Vector2.LEFT
	if Input.is_action_pressed("right"):
		input_vector += Vector2.RIGHT
	input_vector = input_vector.rotated(global_rotation)
	global_position += (Globals.PLAYER_SPEED * input_vector.normalized() * delta)

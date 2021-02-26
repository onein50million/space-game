extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const TOTAL_LIFETIME = 1.0
var lifetime = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime += delta
	default_color.a = 1- lifetime/TOTAL_LIFETIME
	if lifetime > TOTAL_LIFETIME:
		queue_free()

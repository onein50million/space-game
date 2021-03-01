extends Line2D


const TOTAL_LIFETIME = 0.3
var lifetime = 0.0


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime += delta
	default_color.a = 1- lifetime/TOTAL_LIFETIME
	if lifetime > TOTAL_LIFETIME:
		queue_free()

extends Particles2D

var lifetime_left = lifetime

func _ready():
	pass

func _process(delta):
	if not emitting:
		lifetime_left -= delta
		if lifetime_left < 0.0:
			queue_free()

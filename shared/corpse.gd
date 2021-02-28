extends Sprite

const MAX_LIFETIME = 10.0
var lifetime = MAX_LIFETIME

func _ready():
	pass

func _process(delta):

	lifetime -= delta
	if lifetime/MAX_LIFETIME < 0.5:
		$blood.emitting = false
		modulate.a = (lifetime/MAX_LIFETIME)*2.0
	if lifetime < 0.0:
		queue_free()

extends Particles2D

const CHECK_LENGTH = 1
var check = 0
var rng
func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
func _process(delta):
	check += delta
	if check > CHECK_LENGTH:
		check = rng.randf()
		var potential_ship = get_parent().get_parent()
		if "ship_type" in potential_ship:
			emitting = pow(rng.randf(),10) > potential_ship.health/potential_ship.max_health
			if emitting:
				$sound.play()

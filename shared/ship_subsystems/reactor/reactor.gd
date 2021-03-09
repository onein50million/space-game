extends Subsystem

var power = 100
var is_charging = true

func _ready():
	type = "reactor"

func _process(delta):
	
	var ship = get_parent()
	if server_side:
		var added_energy = power*delta
		if is_charging:
			for system in ship.systems:
				if system.type == "capacitor":
					added_energy -= system.charge(added_energy)

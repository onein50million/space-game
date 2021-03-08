extends Subsystem

var power = 100
var is_charging = true

func _ready():
	type = "reactor"

func _process(delta):
	
	var ship = get_parent()
	if server_side:
		var num_capacitors = 0
		var added_energy = power*delta
		if is_charging:
			for system in ship.systems:
				if system.type == "capacitor":
					num_capacitors += 1
			for system in ship.systems:
				if system.type == "capacitor":
					system.charge(added_energy/num_capacitors)

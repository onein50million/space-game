extends Subsystem
var shield_diameter = 400
const MINIMUM_CHARGE = 100

var shield_up_before = false

func _ready():
	$shader_base.scale = Vector2(shield_diameter,shield_diameter)
	$shield_area/collision_circle.shape.radius = shield_diameter/2.0


func _process(delta):
	var total_charge_left = 0
	for system in get_parent().get_parent().systems:
		if system.type == "capacitor":
			total_charge_left += system.max_charge - system.current_charge
	var shield_up = total_charge_left > MINIMUM_CHARGE
	
	if shield_up and not shield_up_before:
		$shield_up_sound.play()
		visible = true
		$shield_area/collision_circle.set_deferred("disabled", false)
	elif not shield_up and shield_up_before:
		$shield_down_sound.play()
		visible = false
		$shield_area/collision_circle.set_deferred("disabled", true)
		
	shield_up_before = shield_up
func damage(damage):
	var damage_left = damage
	var ship = get_parent().get_parent()
	var number_capacitors = 0
	for system in ship.systems:
		if system.type == "capacitor":
			number_capacitors += 1
	if number_capacitors > 0:
		for system in ship.systems:
			if system.type == "capacitor":
				print(damage_left)
				damage_left -= system.charge(damage/number_capacitors) #gives back how much was "eaten"
	damage_left -= ship.damage(damage_left)
	return damage - damage_left

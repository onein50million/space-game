extends Subsystem

var current_charge = 0
var max_charge = 1000

func _ready():
	type = "capacitor"
	latest_data = {
		"current_charge": 0,
		"max_charge": max_charge
		}

func _process(delta):
	if server_side:
		latest_data.current_charge = current_charge
		latest_data.max_charge = max_charge
	else: #client
		current_charge = latest_data.current_charge
		max_charge = latest_data.max_charge
	$sprite/charge.scale = Vector2(current_charge/max_charge, 1.0)
func charge(amount):
	var storage_left = max_charge - current_charge
	if amount < storage_left:
		current_charge += amount
		return amount
	else:
		current_charge += storage_left
		return storage_left

func discharge(amount):
	var amount_discharged = min(amount,current_charge)
	current_charge -= amount_discharged
	return amount_discharged

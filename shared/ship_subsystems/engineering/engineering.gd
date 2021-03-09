extends Subsystem

func _ready():
	type = "engineering"
	client_send_data = {
		"current_target": 69
	}
	latest_data = {
		"current_target": 69
	}
func _process(delta):
	var ship = get_parent()
	
	var total_charge_capacity = 0
	var total_charge = 0
	var total_power = 0
	for system in ship.systems:
		if system.type == "capacitor":
			total_charge_capacity += system.max_charge
			total_charge += system.current_charge
		if system.type == "reactor":
			total_power += system.power
	
	$console/panel/vbox/target_energy/slider.max_value = total_charge_capacity
	$console/panel/vbox/current_target/progress.max_value = total_charge_capacity
	$console/panel/vbox/current_target/progress.value = latest_data.current_target
	$console/panel/vbox/current_energy/amount.text = "%.1f" % total_charge
	$console/panel/vbox/maximum_energy/amount.text = "%.1f" % total_charge_capacity
	$console/panel/vbox/power/amount.text = "%.1f" % total_power
	$console/panel/vbox/integrity/amount.text = "%.1f%%" % ((ship.health/ship.max_health)*100)
	if server_side:
		latest_data.current_target = client_send_data.current_target
		for system in ship.systems:
			if system.type == "reactor":
				system.is_charging = total_charge < latest_data.current_target
	else:
		var client = ship.get_parent()
		if client.local_player.at_console != type:
			$console/panel/vbox/target_energy/slider.value = latest_data.current_target
		client_send_data.current_target = $console/panel/vbox/target_energy/slider.value

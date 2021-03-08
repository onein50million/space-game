extends Subsystem


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	type = "weapons"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var total_max_charge = 0
	var total_current_charge = 0
	for system in get_parent().systems:
		if system.type == "capacitor":
			total_max_charge += system.max_charge
			total_current_charge += system.current_charge
	$console/weapons_control/vbox/capacitor/charge_bar.max_value = total_max_charge
	$console/weapons_control/vbox/capacitor/charge_bar.value = total_current_charge

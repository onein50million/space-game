extends Button

func _pressed():
	$"/root/client".exit_scene("Quit requested")

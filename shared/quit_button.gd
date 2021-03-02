extends Button

func _pressed():
	get_parent().get_parent().get_parent().exit_scene("Quit requested")

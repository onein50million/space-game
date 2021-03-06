extends CheckBox

func _ready():
	pressed = AudioServer.is_bus_mute(0)

func _pressed():
	AudioServer.set_bus_mute(0, pressed)

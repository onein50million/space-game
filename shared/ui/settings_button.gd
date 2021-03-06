extends Button

func _ready():
	$"../settings".visible = false

func _toggled(button_pressed):
	$"../settings".visible = button_pressed
	

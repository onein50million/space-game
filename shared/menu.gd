extends Node
onready var ship_button_group = ButtonGroup.new()
func _ready():

	var directory = Directory.new()
	if directory.open("res://ships/") == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if !directory.current_is_dir():
				var new_ship_button = CheckBox.new()
				new_ship_button.group = ship_button_group
				$Panel/ship_list_container/ship_list_box.add_child(new_ship_button)
				new_ship_button.text = file_name
			file_name = directory.get_next()
func _process(_delta):
	#prevents wierd things form happening when transform changes at last second during scene transition
	get_viewport().canvas_transform.origin = Vector2(0,0)
	get_viewport().canvas_transform.x = Vector2(1,0)
	get_viewport().canvas_transform.y = Vector2(0,1)

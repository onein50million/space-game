extends Subsystem


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	$console/PanelContainer.rect_pivot_offset = $console/PanelContainer.rect_size
	type = "communications"
	latest_data = {
		"missions": [],
		"ship_name" :  "system_uninitialized",

	}
	client_send_data = {
		"request_mission" : false
	}

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	client_send_data.request_mission = $console/PanelContainer/left_vbox/request_mission.pressed
	#lazily setting it each frame even though it shouldn't change
	$console/PanelContainer/left_vbox/ship_name.text = "Ship: %s" % latest_data.ship_name
	for node in $console/PanelContainer/ScrollContainer/VBoxContainer.get_children():
		node.queue_free()
	for mission in latest_data.missions:
		var new_label = Label.new()
		$console/PanelContainer/ScrollContainer/VBoxContainer.add_child(new_label)
		new_label.text = mission.title
		if mission.complete:
			new_label.modulate = Color.green
		else:
			new_label.modulate = Color.red

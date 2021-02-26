extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var type = "communications"
var latest_data = {
	"missions": [],
	"ship_name" :  "system_uninitialized",

}
var client_send_data = {
	"request_mission" : false
}
var server_side = false


var is_open = false #client side
var animation_ratio = 0.0
var animation_speed = 0.1
# Called when the node enters the scene tree for the first time.
func _ready():
	$console/PanelContainer.rect_pivot_offset = $console/PanelContainer.rect_size
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	var window_scale = 1.0
	if is_open:
		animation_speed = 0.1
	else:
		animation_speed = -0.1
	
	animation_ratio = clamp(animation_ratio+animation_speed, 0.0,1.0)
	window_scale = animation_ratio
	$console/PanelContainer.set_scale(Vector2(window_scale,window_scale))

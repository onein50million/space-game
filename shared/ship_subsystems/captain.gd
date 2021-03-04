extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var type = "captain"
var latest_data = {}
var client_send_data = {}
var server_side = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _process(delta):
	var health_ratio = get_parent().health/get_parent().max_health
	if health_ratio < 0.1 and not $warning.playing:
		$warning.play()
	if health_ratio > 0.1:
		$warning.stop()

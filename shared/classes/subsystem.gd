extends Node2D

class_name Subsystem, "res://assets/communications.png"

var type = "none"
var latest_data = {}
var client_send_data = {}
var server_side = false

var is_open = false #client side
var animation_ratio = 0.0
var animation_speed = 0.1

func _ready():
	pass

func _process(delta):
	
	if is_open:
		animation_speed = 5.0
	else:
		animation_speed = -5.0
	
	animation_ratio = clamp(animation_ratio+animation_speed*delta, 0.0,1.0)
	if has_node("console"):
		$console.set_scale(Vector2(animation_ratio,animation_ratio))

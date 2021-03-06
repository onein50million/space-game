extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var lifetime = 1.0
var real_position = Vector2(0,0)
var size = 0.5
# Called when the node enters the scene tree for the first time.
func _ready():
	$ping.volume_db = size*10 - 40.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	if lifetime < 0.0:
		queue_free()
	update()

func _draw():
	var contact_color = Color.green
	contact_color.a = lifetime / get_parent().LIFETIME
	draw_circle(Vector2(0,0),size, contact_color)

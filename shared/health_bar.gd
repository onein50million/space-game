extends Node2D

const WIDTH = 100.0
const HEIGHT = 10.0
func _process(_delta):
	
	update()

func _draw():
	var health_ratio = get_parent().health/get_parent().max_health
	draw_rect(
		Rect2(
			Vector2(0,-HEIGHT/2.0),
			Vector2(WIDTH*health_ratio,HEIGHT)),
			Color.red)

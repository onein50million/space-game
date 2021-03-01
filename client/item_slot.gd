extends Control

export var icon_texture: Texture = null
export var DRAW_TIME = 1.0
onready var draw_lifetime = 0.0

var selected = false

func _ready():
	$TextureRect.texture = icon_texture

func _process(delta):
	if selected:
		calculate_lifetime(delta)
	else:
		draw_lifetime = 0.0
	var icon_height = $TextureRect.texture.get_size().y
	
	$selection.rect_size.y = icon_height*(draw_lifetime/DRAW_TIME)


func calculate_lifetime(delta):
	draw_lifetime = min(DRAW_TIME,draw_lifetime+delta)

extends Control

export var icon_texture: Texture = null
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
	
	$selection.rect_size.y = icon_height*(draw_lifetime/Globals.DRAW_TIME)


func calculate_lifetime(delta):
	draw_lifetime = min(Globals.DRAW_TIME,draw_lifetime+delta)

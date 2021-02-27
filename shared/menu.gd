extends Node

func _process(delta):
	#prevents wierd things form happening when transform changes at last second during scene transition
	get_viewport().canvas_transform.origin = Vector2(0,0)
	get_viewport().canvas_transform.x = Vector2(1,0)
	get_viewport().canvas_transform.y = Vector2(0,1)

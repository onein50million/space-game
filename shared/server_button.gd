extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _pressed():
	print("server")
	
	var server_scene = load("res://server/server.tscn").instance()
	server_scene.port = int(get_node("port").get_text())
	server_scene.menu = get_node("/root/menu")
	get_tree().get_root().add_child(server_scene)
	get_tree().get_root().remove_child(get_node("/root/menu"))

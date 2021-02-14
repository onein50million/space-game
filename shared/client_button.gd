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
	print("client")
	
	var client_scene = load("res://client/client.tscn").instance()
	client_scene.color = get_node("color").get_pick_color()
	client_scene.ip = get_node("ip").get_text()
	client_scene.port = int(get_node("port").get_text())
	client_scene.username = get_node("name").get_text()
	client_scene.ship_name = get_node("ship_name").get_text()
	client_scene.menu = get_node("/root/menu")
	
	get_tree().get_root().add_child(client_scene)
	get_tree().get_root().remove_child(get_node("/root/menu"))

extends Button

func _ready():
	pass

func _pressed():
	var server_node = $"/root/server"
	for _i in range(0, 15):
		server_node.spawn_body(server_node.alien_scene)

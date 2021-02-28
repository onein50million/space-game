extends Button


func _pressed():
	var server_node = $"/root/server"
	for client in server_node.client_list.values():
		client.health -= 10.0
		print("damaged")


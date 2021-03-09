extends Button

func _pressed():
	print("pressed")
	var root_node =  get_tree().get_root()
	if root_node.has_node("server"):
		root_node.get_node("server").exit_scene("Quit requested")
		return
	if root_node.has_node("client"):
		root_node.get_node("client").exit_scene("Quit requested")
		return
	if root_node.has_node("menu"):
		var confirm_dialog = ConfirmationDialog.new()
		get_parent().add_child(confirm_dialog)
		confirm_dialog.dialog_text = "Are you sure you would like to quit?"
		confirm_dialog.popup_centered()
		confirm_dialog.get_ok().connect("pressed", self, "quit_game")
		return	
		
func quit_game():
	get_tree().quit()

extends Sprite

var server_side = true
var type
var slot_number

var draw_lifetime = 0.0

var player
var client
var server
var item_slot

func _ready():
	if server_side:
		return

	pass

func _process(delta):
	player = $"../.."
	if player.input_buffer[player.input_buffer_head].slot == slot_number:
		draw_lifetime = min(draw_lifetime+delta,Globals.DRAW_TIME)
	else:
		draw_lifetime = 0.0

	if server_side:
		server = player.get_parent().get_parent()
		return
	


	client = player.get_parent().get_parent()
	item_slot = client.get_node("ui/item_slots/").get_node(type)
	
	visible = (player.last_known_slot == slot_number and item_slot.draw_lifetime >= Globals.DRAW_TIME)


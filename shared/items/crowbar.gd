extends "res://shared/items/item.gd"

const REPAIR_RATE = 100.0

func _ready():
	type = "crowbar"
	slot_number = 1


func _physics_process(_delta):
	if firing and draw_lifetime >= Globals.DRAW_TIME:
		repair(player.get_parent())

func repair(target):
	target.health = min(target.max_health,target.health + REPAIR_RATE*(1.0/Globals.BUFFER_LENGTH))


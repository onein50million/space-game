extends "res://shared/items/item.gd"

const HEAL_RATE = 100.0

func _ready():
	type = "medkit"
	slot_number = 2

func _physics_process(_delta):

	if firing and draw_lifetime >= Globals.DRAW_TIME:
		heal(player)

func heal(target):
	target.health = min(target.max_health,target.health + HEAL_RATE*(1.0/Globals.BUFFER_LENGTH))

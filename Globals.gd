extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const NETWORK_UPDATE_INTERVAL = Engine.iterations_per_second
const BUFFER_LENGTH = 3 * NETWORK_UPDATE_INTERVAL
const PLAYER_SPEED = 100.0
const DEFAULT_ZOOM = 300.0

const GAME_AREA = Rect2(-1000.0,-1000.0,2000.0,2000.0)
const SAFE_DISTANCE = 100.0 #for spawning things
# Called when the node enters the scene tree for the first time.
func _ready():
	print("BUFFER: %s" % BUFFER_LENGTH)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

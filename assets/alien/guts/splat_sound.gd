extends AudioStreamPlayer2D

func _ready():
	pass


func _on_splat_sound_finished():
	queue_free()

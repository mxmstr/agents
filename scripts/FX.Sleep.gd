extends Node2D

export var direction = Vector2(0, 0)


func _ready():
	
	$Timer.connect('timeout', self, '_on_timeout')


func _process(delta):
	
	position += direction * delta
	
	$Label.self_modulate.a = $Timer.time_left / $Timer.wait_time


func _on_timeout():
	
	queue_free()


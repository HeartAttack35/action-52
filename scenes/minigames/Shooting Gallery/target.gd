extends Area2D
## target.gd
## Blanco estático con tiempo de vida propio (LifeTimer).
## Desaparece al expirar el timer (sin penalización) o al recibir un
## proyectil (suma 10 puntos). Incluye guard contra doble queue_free.

var _dead: bool = false


func _ready() -> void:
	$LifeTimer.wait_time = randf_range(1.5, 3.0)


func _on_life_timer_timeout() -> void:
	if _dead:
		return
	_dead = true
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("proyectiles"):
		_dead = true
		GameManager.add_score(10)
		area.queue_free()
		queue_free()

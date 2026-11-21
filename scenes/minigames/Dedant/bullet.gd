extends Area2D
## bullet.gd  (Dedant)
## Proyectil disparado por el jugador. Se mueve hacia arriba a velocidad
## constante y se elimina al salir de la pantalla.

const SPEED: float = 500.0


func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

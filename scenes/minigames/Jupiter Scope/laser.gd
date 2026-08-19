extends Area2D
## laser.gd
## Proyectil disparado por el jugador. Se mueve hacia arriba a velocidad constante.
## Se elimina automáticamente al salir de la pantalla.

const SPEED: float = 500.0


func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

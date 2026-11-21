extends Area2D
## bullet.gd (Beeps and Blips)
## Proyectil disparado por el jugador hacia arriba.
## Se elimina automáticamente al salir por el borde superior mediante VisibleOnScreenNotifier2D.

const SPEED: float = 500.0


func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

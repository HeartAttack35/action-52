extends Area2D
## laser.gd  (Spread-Fire)
## Proyectil con dirección arbitraria. La dirección se asigna desde la
## escena principal justo después de instanciar el nodo.

const SPEED: float = 500.0

## Dirección normalizada asignada al instanciar (default: arriba).
var direction: Vector2 = Vector2.UP


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

extends Area2D
## laser.gd  (They Came from Outer Space)
## Proyectil con dirección arbitraria. Se asigna desde la escena principal
## antes de add_child(). Se elimina al salir de pantalla.

const SPEED: float = 550.0

var direction: Vector2 = Vector2.UP


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

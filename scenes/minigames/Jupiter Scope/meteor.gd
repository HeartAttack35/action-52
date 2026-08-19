extends Area2D
## meteor.gd
## Obstáculo que cae desde la parte superior de la pantalla.
## Destruye proyectiles que choquen con él (suma puntos) y
## quita vidas al jugador si lo alcanza.

const SPEED: float = 150.0


func _physics_process(delta: float) -> void:
	position.y += SPEED * delta


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("proyectiles"):
		GameManager.add_score(10)
		area.queue_free()
		queue_free()
	elif area.is_in_group("jugador"):
		_hit_jugador()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_hit_jugador()


func _hit_jugador() -> void:
	GameManager.lose_life()
	queue_free()

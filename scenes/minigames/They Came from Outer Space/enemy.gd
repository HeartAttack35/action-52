extends Area2D
## enemy.gd  (They Came from Outer Space)
## Nave enemiga que cruza la pantalla en trayectoria horizontal o diagonal.
## La dirección se asigna desde la escena principal al instanciar.
##
## Comportamiento:
##   - Proyectil ("proyectiles") la impacta → +10 pts, muere.
##   - Choca con el jugador ("jugador")     → GameManager.lose_life(), muere.
##   - Sale de pantalla sin impactar        → se elimina sin penalización.

const SPEED: float = 160.0

var direction: Vector2 = Vector2(1.0, 0.0)

var _dead: bool = false


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not _dead:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("proyectiles"):
		_dead = true
		GameManager.add_score(10)
		area.queue_free()
		queue_free()
	elif area.is_in_group("jugador"):
		_hit_player()


func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("jugador"):
		_hit_player()


func _hit_player() -> void:
	_dead = true
	GameManager.lose_life()
	queue_free()

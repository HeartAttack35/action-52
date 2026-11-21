extends Area2D
## enemy.gd  (Shooting Gallery)
## Enemigo que cruza la pantalla de derecha a izquierda en trayectoria
## horizontal. Si llega al borde izquierdo, resta una vida al jugador.
## Si un proyectil del grupo "proyectiles" lo impacta, suma 20 puntos.

const SPEED: float = 150.0

var _dead: bool = false


func _physics_process(delta: float) -> void:
	position.x -= SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if _dead:
		return
	# Solo penaliza si sale por la izquierda (x negativa)
	if position.x < 0:
		_dead = true
		GameManager.lose_life()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("proyectiles"):
		_dead = true
		GameManager.add_score(20)
		area.queue_free()
		queue_free()

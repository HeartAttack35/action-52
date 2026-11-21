extends Area2D
## enemy_ship.gd  (Spread-Fire)
## Nave enemiga que desciende en diagonal.
## La dirección diagonal se asigna al instanciar desde la escena principal.
##
## Comportamiento:
##   - Proyectil del grupo "proyectiles" la impacta → +10 puntos, muere.
##   - Choca con el jugador (grupo "jugador")       → derrota inmediata.
##   - Sale por el borde inferior sin impactar      → solo se elimina
##     (la penalización de vida queda a criterio de diseño; aquí no resta
##     para mantener la derrota solo por colisión directa, igual que el
##     enunciado indica).

const SPEED: float = 180.0

## Dirección normalizada (diagonal). Se setea al instanciar.
var direction: Vector2 = Vector2(0.0, 1.0)

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
		_on_hit_player()


func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("jugador"):
		_on_hit_player()


func _on_hit_player() -> void:
	_dead = true
	queue_free()
	# Derrota inmediata: agota todas las vidas restantes
	while GameManager.lives > 0:
		GameManager.lose_life()

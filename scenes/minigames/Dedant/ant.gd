extends Area2D
## ant.gd  (Dedant)
## Enemigo (hormiga) que cae desde la parte superior de la pantalla hacia
## abajo a velocidad constante.
##
## Comportamiento:
##   - Si un proyectil del grupo "proyectiles" lo impacta → +10 puntos, muere.
##   - Si alcanza el borde inferior de la pantalla     → pierde una vida, muere.

const SPEED: float = 150.0

var _dead: bool = false


func _physics_process(delta: float) -> void:
	position.y += SPEED * delta


func _process(_delta: float) -> void:
	if _dead:
		return
	# Detectar salida por el borde inferior
	if position.y > get_viewport_rect().size.y + 20.0:
		_dead = true
		GameManager.lose_life()
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("proyectiles"):
		_dead = true
		GameManager.add_score(10)
		area.queue_free()
		queue_free()

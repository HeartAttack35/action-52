extends Area2D
## enemy.gd (Beeps and Blips)
## Entidad abstracta enemiga que desciende hacia la parte inferior de la pantalla.
## Otorga puntaje al ser destruida por un proyectil y quita una vida si colisiona con el jugador o cruza la pantalla.

const SPEED: float = 160.0

var _dead: bool = false
var _rot_speed: float = 2.0


func _ready() -> void:
	# Rotación abstracta con velocidad y sentido aleatorios
	_rot_speed = randf_range(1.5, 3.5) * (1.0 if randf() > 0.5 else -1.0)


func _physics_process(delta: float) -> void:
	position.y += SPEED * delta
	rotation += _rot_speed * delta


func _process(_delta: float) -> void:
	if _dead:
		return
	# Si sobrepasa el borde inferior de la pantalla sin ser destruido
	if position.y > get_viewport_rect().size.y + 30.0:
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


func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("jugador"):
		_dead = true
		GameManager.lose_life()
		queue_free()

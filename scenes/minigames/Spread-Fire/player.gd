extends CharacterBody2D
## player.gd  (Spread-Fire)
## Nave del jugador. Se mueve horizontalmente (←/→) con posición Y fija en
## el borde inferior. Al disparar emite shoot_requested con las tres
## direcciones del disparo triple:
##   • 0°   → vertical puro (arriba)
##   • +20° → inclinado a la derecha
##   • -20° → inclinado a la izquierda

const SPEED: float = 300.0

## Emite la posición de disparo y la dirección normalizada del proyectil.
signal shoot_requested(position: Vector2, direction: Vector2)

## Ángulos de los tres láseres en grados (0 = arriba, positivo = derecha).
const SPREAD_ANGLES: Array[float] = [0.0, 20.0, -20.0]


func _physics_process(_delta: float) -> void:
	var dir: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * SPEED
	velocity.y = 0.0
	move_and_slide()
	position.x = clamp(position.x, 0.0, get_viewport_rect().size.x)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	var origin: Vector2 = $ShootPoint.global_position
	for deg in SPREAD_ANGLES:
		# Vector base: arriba (-Y). Rotamos en radianes.
		var rad: float = deg_to_rad(deg)
		var direction: Vector2 = Vector2(sin(rad), -cos(rad))
		shoot_requested.emit(origin, direction)

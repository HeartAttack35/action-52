extends CharacterBody2D
## player.gd  (Dedant)
## Nave controlada por el jugador. Se mueve horizontalmente (←/→) con
## posición Y fija en el borde inferior. Emite una señal al disparar
## para que la escena principal instancie la bala.

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	velocity.y = 0.0
	move_and_slide()
	# Mantener dentro del ancho de pantalla
	position.x = clamp(position.x, 0.0, get_viewport_rect().size.x)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit($ShootPoint.global_position)

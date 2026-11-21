extends CharacterBody2D
## player.gd  (Shooting Gallery)
## Pistolero fijo en el borde izquierdo. Se mueve verticalmente (↑/↓) y emite
## una señal cuando dispara para que la escena principal instancie la bala.

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("ui_up", "ui_down")
	velocity.y = direction * SPEED
	velocity.x = 0.0
	move_and_slide()
	# Mantener X fija en el borde izquierdo (la escena la posiciona al inicio).
	position.x = get_parent().get_viewport_rect().size.x * 0.0 + 50.0
	var half_h: float = 20.0
	position.y = clamp(position.y, half_h, get_viewport_rect().size.y - half_h)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit($ShootPoint.global_position)

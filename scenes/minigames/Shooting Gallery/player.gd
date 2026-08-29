extends CharacterBody2D
## player.gd  (Shooting Gallery)
## Pistolero controlado por el jugador. Se mueve horizontalmente y emite
## una señal cuando dispara para que la escena principal instancie la bala.

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	move_and_slide()
	var half_w: float = 16.0
	position.x = clamp(position.x, half_w, get_viewport_rect().size.x - half_w)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit($ShootPoint.global_position)

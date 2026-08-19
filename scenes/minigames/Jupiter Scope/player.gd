extends CharacterBody2D
## player.gd
## Nave controlada por el jugador. Se mueve horizontalmente y emite una señal
## cuando dispara para que la escena principal instancie el láser.

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	move_and_slide()
	position.x = clamp(position.x, 0.0, get_viewport_rect().size.x)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit($ShootPoint.global_position)

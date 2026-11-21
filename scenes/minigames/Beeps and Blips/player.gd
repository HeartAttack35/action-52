extends CharacterBody2D
## player.gd (Beeps and Blips)
## Personaje simplificado (bloques minimalistas de color) controlado en un solo eje horizontal.
## Dispara proyectiles hacia arriba desde ShootPoint al presionar ui_accept.

const SPEED: float = 320.0

signal shoot_requested(position: Vector2)

@onready var shoot_point: Marker2D = $ShootPoint


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	velocity.y = 0.0
	move_and_slide()

	# Confinamiento horizontal dentro de los límites de la pantalla
	var half_w: float = 24.0
	position.x = clamp(position.x, half_w, get_viewport_rect().size.x - half_w)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit(shoot_point.global_position)

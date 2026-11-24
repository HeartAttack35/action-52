class_name RollingBall
extends CharacterBody2D
## rolling_ball.gd
## Obstáculo dinámico de "Hambo's Adventures".
## Bola rodante que avanza horizontalmente sobre plataformas, cae por gravedad al
## vaciarse el suelo e invierte su sentido de avance al aterrizar para descender en zigzag.
## Daña al jugador al impactar y se destruye al alcanzar la base de la pantalla.

signal player_hit(player: Node2D)
signal direction_changed(new_direction: float)

@export var speed: float = 140.0
@export var direction: float = 1.0 # 1.0: derecha, -1.0: izquierda
@export var roll_rotation_speed: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _was_on_floor: bool = false
var _has_fallen: bool = false


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("hazard")
	add_to_group("rolling_ball")
	add_to_group("obstaculo")

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)


func setup(initial_direction: float = 1.0, initial_speed: float = 140.0) -> void:
	direction = initial_direction
	speed = initial_speed


func _physics_process(delta: float) -> void:
	_apply_gravity_and_zigzag(delta)
	_apply_movement(delta)
	_check_bounds()


func _apply_gravity_and_zigzag(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
		if _was_on_floor:
			# Acaba de caer de una plataforma
			_has_fallen = true
	else:
		velocity.y = 0.0
		if _has_fallen:
			# Aterrizó en la plataforma inferior -> invertir sentido para descenso en zigzag
			direction = -direction
			direction_changed.emit(direction)
			_has_fallen = false

	_was_on_floor = is_on_floor()


func _apply_movement(delta: float) -> void:
	velocity.x = direction * speed
	move_and_slide()

	# Si choca contra una pared, también invierte el avance
	if is_on_wall():
		direction = -direction
		direction_changed.emit(direction)

	# Rotación visual continua de rodamiento
	if sprite:
		sprite.rotation += direction * roll_rotation_speed * delta


func _check_bounds() -> void:
	# Si cae por debajo de la base visible del nivel, se elimina
	if global_position.y > 640.0:
		queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage()
		player_hit.emit(body)


func _on_screen_exited() -> void:
	# Eliminar cuando sale por la parte inferior o laterales de la pantalla
	if global_position.y > 520.0 or global_position.x < -40.0 or global_position.x > 840.0:
		queue_free()

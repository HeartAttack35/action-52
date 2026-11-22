extends CharacterBody2D
## enemy.gd  (Chill-Out)
## Esquimal rival que patrulla plataformas fijas, cambia de dirección
## al llegar al borde o muro, y lanza bolas de nieve periódicamente.

signal defeated(enemy: CharacterBody2D)

@export var speed: float = 65.0
@export var shoot_interval_min: float = 2.0
@export var shoot_interval_max: float = 4.0
@export var snowball_scene: PackedScene = preload("res://scenes/minigames/Chill-Out/snowball.tscn")

var direction: float = 1.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_ray: RayCast2D = $LedgeRayCast
@onready var wall_ray: RayCast2D = $WallRayCast
@onready var shoot_timer: Timer = $ShootTimer
@onready var shoot_point: Marker2D = $ShootPoint
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemigo")
	# Elegir dirección inicial aleatoria (izquierda o derecha)
	direction = 1.0 if randf() > 0.5 else -1.0
	_update_facing()

	shoot_timer.wait_time = randf_range(shoot_interval_min, shoot_interval_max)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Gravedad
	if not is_on_floor():
		velocity.y += _gravity * delta

	# Movimiento horizontal
	velocity.x = direction * speed
	move_and_slide()

	# Detección de muros o bordes de plataforma
	var at_wall: bool = is_on_wall() or wall_ray.is_colliding()
	var at_edge: bool = is_on_floor() and not ledge_ray.is_colliding()

	var vp_size := get_viewport_rect().size
	var at_screen_boundary: bool = false
	if vp_size.x > 0.0:
		if (global_position.x <= 20.0 and direction < 0.0) or (global_position.x >= vp_size.x - 20.0 and direction > 0.0):
			at_screen_boundary = true

	if at_wall or at_edge or at_screen_boundary:
		_turn_around()


func _turn_around() -> void:
	direction = -direction
	_update_facing()


func _update_facing() -> void:
	if sprite:
		sprite.flip_h = (direction < 0.0)
	if ledge_ray:
		ledge_ray.position.x = 20.0 * direction
	if wall_ray:
		wall_ray.target_position = Vector2(26.0 * direction, 0.0)
	if shoot_point:
		shoot_point.position.x = 26.0 * direction


func _on_shoot_timer_timeout() -> void:
	if _is_dead or not is_inside_tree():
		return
	_shoot_snowball()
	shoot_timer.wait_time = randf_range(shoot_interval_min, shoot_interval_max)
	shoot_timer.start()


func _shoot_snowball() -> void:
	if not snowball_scene:
		return
	var ball = snowball_scene.instantiate()
	ball.global_position = shoot_point.global_position
	ball.setup(Vector2(direction, 0.0), true) # true indica proyectil enemigo
	get_parent().add_child(ball)


func hit() -> void:
	if _is_dead:
		return
	_is_dead = true
	GameManager.add_score(100)
	defeated.emit(self)

	# Desactivar colisiones inmediatamente
	collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	# Pequeña animación de derrota (parpadeo y caída o desvanecimiento)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.2), 0.25)
	await tween.finished
	queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_dead:
		return
	if body.is_in_group("player") or body.is_in_group("jugador") or body is FixedPlatformerController:
		if body.has_method("take_damage"):
			body.take_damage()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if _is_dead:
		return
	if area.is_in_group("player_snowball"):
		area.queue_free()
		hit()

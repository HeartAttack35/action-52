class_name ShadowEnemy
extends CharacterBody2D
## shadow_enemy.gd
## Sombra espectral que patrulla horizontalmente los pisos del edificio en "Illuminator".
## Se vaporiza al impactar con el haz luminoso del jugador, emitiendo señales para
## restaurar la iluminación del edificio, y daña al protagonista al contacto físico.

signal defeated(enemy: CharacterBody2D)
signal light_restored(amount: float)

@export var speed: float = 70.0
@export var score_value: int = 100
@export var light_restore_amount: float = 1.0
@export var initial_direction: float = 0.0

var direction: float = 1.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _is_dead: bool = false
var _bob_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_ray: RayCast2D = $LedgeRayCast
@onready var wall_ray: RayCast2D = $WallRayCast
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemigo")
	add_to_group("shadow")

	if initial_direction != 0.0:
		direction = 1.0 if initial_direction > 0.0 else -1.0
	else:
		direction = 1.0 if randf() > 0.5 else -1.0
	_update_facing()

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_bob_time += delta
	if sprite:
		sprite.position.y = sin(_bob_time * 4.5) * 2.5

	if not is_on_floor():
		velocity.y += _gravity * delta

	velocity.x = direction * speed
	move_and_slide()

	var at_wall: bool = is_on_wall() or (wall_ray and wall_ray.is_colliding())
	var at_edge: bool = is_on_floor() and ledge_ray and not ledge_ray.is_colliding()

	var vp_size := get_viewport_rect().size
	var at_screen_boundary: bool = false
	if vp_size.x > 0.0:
		if (global_position.x <= 28.0 and direction < 0.0) or (global_position.x >= vp_size.x - 28.0 and direction > 0.0):
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
		ledge_ray.position.x = 18.0 * direction
	if wall_ray:
		wall_ray.target_position = Vector2(24.0 * direction, 0.0)


func hit() -> void:
	if _is_dead:
		return
	_is_dead = true
	GameManager.add_score(score_value)
	light_restored.emit(light_restore_amount)
	defeated.emit(self)

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	if sprite:
		sprite.modulate = Color(2.2, 2.2, 1.6, 1.0)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.25)
		await tween.finished
	queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_dead:
		return
	if body.is_in_group("player") or body.is_in_group("jugador") or body is FixedPlatformerController:
		if body.has_method("take_damage"):
			body.take_damage()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if _is_dead or area.is_queued_for_deletion():
		return
	if area.is_in_group("player_projectile") or area.is_in_group("light_beam"):
		area.queue_free()
		hit()

class_name LightBeam
extends Area2D
## light_beam.gd
## Ráfaga / haz luminoso horizontal disparado desde la linterna del protagonista.
## Posee alcance corto-medio para iluminar pasillos y vaporizar sombras enemigas.

signal hit_enemy(enemy: Node2D)

@export var speed: float = 460.0
@export var lifetime: float = 0.36

var direction: Vector2 = Vector2.RIGHT
var _consumed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	add_to_group("player_projectile")
	add_to_group("light_beam")

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)

	_update_appearance()


func setup(dir: Vector2) -> void:
	if dir.length() > 0.0:
		direction = dir.normalized()
	else:
		direction = Vector2.RIGHT
	if is_inside_tree():
		_update_appearance()


func _update_appearance() -> void:
	if sprite:
		sprite.flip_h = (direction.x < 0.0)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if sprite:
		sprite.scale.x = move_toward(sprite.scale.x, 1.5, delta * 2.5)


func _on_body_entered(body: Node2D) -> void:
	if _consumed:
		return

	if body is TileMap or body is StaticBody2D:
		_consumed = true
		queue_free()
		return

	if body.is_in_group("enemy") or body.is_in_group("enemigo") or body.is_in_group("shadow"):
		_consumed = true
		if body.has_method("hit"):
			body.hit()
		hit_enemy.emit(body)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _consumed:
		return

	var target: Node = area if (area.is_in_group("enemy") or area.is_in_group("enemigo") or area.is_in_group("shadow")) else area.get_parent()
	if target and (target.is_in_group("enemy") or target.is_in_group("enemigo") or target.is_in_group("shadow")):
		_consumed = true
		if target.has_method("hit"):
			target.hit()
		hit_enemy.emit(target)
		queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_screen_exited() -> void:
	queue_free()

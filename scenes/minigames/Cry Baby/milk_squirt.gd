extends Area2D
## milk_squirt.gd
## Proyectil de chorro de leche del biberón / mamadera del bebé.
## Posee un alcance deliberadamente corto (vida de 0.25 s y fuerte desaceleración)
## para obligar al jugador a disparar en combate cercano.
## Se autodestruye al chocar contra plataformas/TileMap o impactar enemigos.

signal hit_enemy(enemy: Node2D)

@export var speed: float = 340.0
@export var deceleration: float = 650.0
@export var lifetime: float = 0.25

var direction: Vector2 = Vector2.RIGHT
var current_speed: float = 340.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	add_to_group("player_projectile")
	add_to_group("milk_squirt")

	current_speed = speed
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
	current_speed = speed
	if is_inside_tree():
		_update_appearance()


func _update_appearance() -> void:
	if sprite:
		sprite.flip_h = (direction.x < 0.0)


func _physics_process(delta: float) -> void:
	# Desaceleración fuerte hacia el final del alcance
	current_speed = max(0.0, current_speed - deceleration * delta)
	position += direction * current_speed * delta

	# Pequeña expansión visual al avanzar simulando el chorro salpicando
	if sprite:
		sprite.scale = sprite.scale.move_toward(Vector2(1.2, 1.2), delta * 2.0)


func _on_body_entered(body: Node2D) -> void:
	# Autodestrucción contra el terreno / plataformas / TileMap
	if body is TileMap or body is StaticBody2D:
		queue_free()
		return

	# Impacto con enemigo
	if body.is_in_group("enemy") or body.is_in_group("enemigo"):
		if body.has_method("hit"):
			body.hit()
		hit_enemy.emit(body)
		queue_free()
		return


func _on_area_entered(area: Area2D) -> void:
	# Soporte para hitbox en Area2D
	var target = area if (area.is_in_group("enemy") or area.is_in_group("enemigo")) else area.get_parent()
	if target and (target.is_in_group("enemy") or target.is_in_group("enemigo")):
		if target.has_method("hit"):
			target.hit()
		hit_enemy.emit(target)
		queue_free()
		return


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_screen_exited() -> void:
	queue_free()

extends Area2D
## rolling_pin.gd
## Utensilio arrojadizo (rodillo de cocina) del panadero.
## Vuela horizontalmente a corta/media distancia girando en el aire
## y se destruye al impactar con plataformas o comida rebelde.

signal hit_enemy(enemy: Node2D)

@export var speed: float = 320.0
@export var lifetime: float = 0.7

var direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	add_to_group("player_projectile")
	add_to_group("utensil")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)


func setup(dir: Vector2) -> void:
	if dir.length() > 0:
		direction = dir.normalized()
	else:
		direction = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	# Giro continuo en el aire para simular el vuelo del utensilio
	if sprite:
		var spin_dir: float = 1.0 if direction.x >= 0 else -1.0
		sprite.rotation += 16.0 * delta * spin_dir


func _on_body_entered(body: Node2D) -> void:
	# Impacto con terreno / estantes / plataformas sólidas
	if body is TileMap or body is StaticBody2D:
		queue_free()
		return

	# Impacto con enemigo (comida rebelde)
	if body.is_in_group("enemy") or body.is_in_group("enemigo"):
		if body.has_method("hit"):
			body.hit()
		hit_enemy.emit(body)
		queue_free()
		return


func _on_area_entered(area: Area2D) -> void:
	# En caso de que el enemigo use Area2D como cuerpo o hitbox
	var parent: Node = area.get_parent()
	if area.is_in_group("enemy") or area.is_in_group("enemigo"):
		if area.has_method("hit"):
			area.hit()
		hit_enemy.emit(area)
		queue_free()
		return
	elif parent and (parent.is_in_group("enemy") or parent.is_in_group("enemigo")):
		if parent.has_method("hit"):
			parent.hit()
		hit_enemy.emit(parent)
		queue_free()
		return


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_screen_exited() -> void:
	queue_free()

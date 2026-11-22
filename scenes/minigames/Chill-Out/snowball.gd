extends Area2D
## snowball.gd
## Proyectil de bola de nieve usado tanto por el jugador como por los rivales.
## Se desplaza horizontalmente y se destruye al chocar con suelo/plataformas o enemigos.

const SPEED: float = 280.0
const ENEMY_TEXTURE: Texture2D = preload("res://scenes/minigames/Chill-Out/sprites/snowball_enemy.png")
const PLAYER_TEXTURE: Texture2D = preload("res://scenes/minigames/Chill-Out/sprites/snowball.png")

@export var is_enemy: bool = false
var direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	notifier.screen_exited.connect(_on_screen_exited)
	_update_appearance()


func setup(dir: Vector2, enemy: bool = false) -> void:
	direction = dir.normalized()
	is_enemy = enemy
	if is_inside_tree():
		_update_appearance()


func _update_appearance() -> void:
	if sprite:
		sprite.texture = ENEMY_TEXTURE if is_enemy else PLAYER_TEXTURE
	if is_enemy:
		add_to_group("enemy_snowball")
		remove_from_group("player_snowball")
	else:
		add_to_group("player_snowball")
		remove_from_group("enemy_snowball")


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	# Efecto visual de rodar / girar en el aire
	if sprite:
		sprite.rotation += 10.0 * delta * (1.0 if direction.x >= 0 else -1.0)


func _on_body_entered(body: Node2D) -> void:
	# Impacto con terreno / plataformas
	if body is TileMap or body is StaticBody2D:
		_impact()
		return

	# Impacto de proyectil de jugador contra esquimal rival
	if not is_enemy and (body.is_in_group("enemy") or body.is_in_group("enemigo")):
		if body.has_method("hit"):
			body.hit()
		_impact()
		return

	# Impacto de proyectil enemigo contra el jugador
	if is_enemy and (body.is_in_group("player") or body.is_in_group("jugador") or body is FixedPlatformerController):
		if body.has_method("take_damage"):
			body.take_damage()
		_impact()
		return


func _on_area_entered(area: Area2D) -> void:
	# Choque entre bolas de nieve opuestas
	if is_enemy and area.is_in_group("player_snowball"):
		area.queue_free()
		_impact()
		return
	elif not is_enemy and area.is_in_group("enemy_snowball"):
		area.queue_free()
		_impact()
		return

	# Si el enemigo o jugador usan hitboxes en Area2D
	if not is_enemy:
		var parent = area.get_parent()
		if parent and (parent.is_in_group("enemy") or parent.is_in_group("enemigo")):
			if parent.has_method("hit"):
				parent.hit()
			_impact()
			return
	else:
		var parent = area.get_parent()
		if parent and (parent.is_in_group("player") or parent.is_in_group("jugador") or parent is FixedPlatformerController):
			if parent.has_method("take_damage"):
				parent.take_damage()
			_impact()
			return


func _impact() -> void:
	queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_screen_exited() -> void:
	queue_free()

class_name UndergroundGem
extends Area2D
## gem.gd (Underground)
## Gema o tesoro designado en la caverna.
## Si el explorador alcanza la gema, se activa la condición de victoria.

signal collected(body: Node2D)

var _base_y: float = 0.0
var _time: float = 0.0
var _is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("gem")
	add_to_group("gema")
	add_to_group("exit")
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _is_collected:
		return
	_time += delta * 4.0
	position.y = _base_y + sin(_time) * 4.0


func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body.is_in_group("player") or body.is_in_group("jugador") or body is FixedPlatformerController:
		_is_collected = true
		GameManager.add_score(500)
		collected.emit(body)

		if collision_shape:
			collision_shape.set_deferred("disabled", true)

		# Animación de recogida
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
			tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
			await tween.finished
		queue_free()

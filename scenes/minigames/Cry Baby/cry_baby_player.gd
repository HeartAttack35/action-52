extends FixedPlatformerController
## cry_baby_player.gd
## Controlador del bebé protagonista de "Cry Baby".
## Hereda de FixedPlatformerController (PlatformerPlayerBase).
## Gestiona el disparo de chorros de leche desde el biberón, el daño recibido y la invulnerabilidad.

signal damage_taken

var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.2


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")
	add_to_group("baby")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	# Protección de seguridad contra caída fuera del escenario
	var vp_size := get_viewport_rect().size
	var max_y: float = vp_size.y + 40.0 if vp_size.y > 0.0 else 640.0
	if global_position.y > max_y:
		global_position = Vector2(400.0, 500.0)
		velocity = Vector2.ZERO
		take_damage()


func take_damage() -> void:
	if is_invulnerable:
		return

	is_invulnerable = true
	_invulnerability_timer = INVULNERABILITY_DURATION
	GameManager.lose_life()
	damage_taken.emit()

	# Retroceso físico al ser golpeado
	velocity.y = -150.0
	velocity.x = -facing_direction * 110.0

	# Efecto visual de parpadeo durante la invulnerabilidad
	if _sprite:
		var tween = create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

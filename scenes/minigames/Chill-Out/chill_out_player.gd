extends FixedPlatformerController
## chill_out_player.gd
## Controlador del esquimal protagonista en Chill-Out.
## Hereda de FixedPlatformerController y añade gestión de daño/invulnerabilidad.

signal damage_taken

var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.2


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")


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

	# Pequeño retroceso al recibir impacto
	velocity.y = -160.0
	velocity.x = -facing_direction * 120.0

	# Efecto visual de parpadeo de invulnerabilidad
	if _sprite:
		var tween = create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

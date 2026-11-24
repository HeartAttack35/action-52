class_name HamboPlayer
extends FixedPlatformerController
## hambo_player.gd
## Cerdo antropomorfo protagonista en "Hambo's Adventures".
## Hereda de FixedPlatformerController y añade mecánicas de escalado en escaleras,
## suspensión de gravedad durante la escalada y gestión de daño/invulnerabilidad.
## Desactiva la máscara de colisión de plataformas mientras se mueve verticalmente
## en la escalera para permitir atravesar pisos.

signal damage_taken

@export var climb_speed: float = 140.0

var is_on_ladder: bool = false
var is_climbing: bool = false
var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.2

var _ladders: Array[Area2D] = []
var _spawn_position: Vector2 = Vector2(80.0, 520.0)


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")
	_spawn_position = global_position


func is_near_ladder() -> bool:
	return is_on_ladder or _ladders.size() > 0


func _on_ladder_area_entered(_area: Area2D = null) -> void:
	is_on_ladder = true
	is_climbing = true
	if _area and not _ladders.has(_area):
		_ladders.append(_area)


func _on_ladder_area_exited(_area: Area2D = null) -> void:
	if _area:
		_ladders.erase(_area)
	if _ladders.is_empty():
		is_on_ladder = false
		is_climbing = false
		# Al salir de la escalera, reactivamos de inmediato la colisión con el suelo
		set_collision_mask_value(1, true)


func enter_ladder(ladder: Area2D) -> void:
	_on_ladder_area_entered(ladder)


func exit_ladder(ladder: Area2D) -> void:
	_on_ladder_area_exited(ladder)


func start_climbing() -> void:
	if is_near_ladder():
		is_on_ladder = true
		is_climbing = true


func stop_climbing() -> void:
	is_on_ladder = false
	is_climbing = false
	set_collision_mask_value(1, true)


func apply_climb_direction(vertical_dir: float) -> void:
	velocity.y = vertical_dir * climb_speed
	if abs(vertical_dir) > 0.1:
		set_collision_mask_value(1, false)
	else:
		set_collision_mask_value(1, true)


func _physics_process(delta: float) -> void:
	if is_on_ladder and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")):
		# Mientras se mueva verticalmente en la escalera, ignora el suelo
		set_collision_mask_value(1, false)
		velocity.y = Input.get_axis("ui_up", "ui_down") * climb_speed
	elif is_on_ladder:
		velocity.y = 0.0
		set_collision_mask_value(1, true)
	else:
		# Estado normal de plataformas
		set_collision_mask_value(1, true)
		_apply_gravity(delta)
		_handle_jump()

	_handle_movement()
	_handle_attack()
	move_and_slide()
	_clamp_to_viewport()
	_tick_melee_timer(delta)

	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	_check_pit_boundary()


func _apply_gravity(delta: float) -> void:
	if is_on_ladder or is_climbing:
		velocity.y = 0.0
		return
	super._apply_gravity(delta)


func _handle_jump() -> void:
	if is_on_ladder or is_climbing:
		return
	super._handle_jump()


func _check_pit_boundary() -> void:
	# Caída al vacío (debajo del nivel inferior)
	if global_position.y > 640.0:
		global_position = _spawn_position
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
	velocity.y = -150.0
	velocity.x = -facing_direction * 100.0

	# Efecto visual de parpadeo de invulnerabilidad
	if _sprite:
		var tween = create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

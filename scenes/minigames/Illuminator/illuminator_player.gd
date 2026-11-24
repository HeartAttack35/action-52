class_name IlluminatorPlayer
extends FixedPlatformerController
## illuminator_player.gd
## Protagonista con linterna del minijuego "Illuminator".
## Hereda de FixedPlatformerController y añade escalado en escaleras con
## soporte para plataformas One-Way Collision, disparo de haz luminoso,
## y gestión de daño e invulnerabilidad.

signal damage_taken

@export var climb_speed: float = 140.0

var is_on_ladder: bool = false
var is_climbing: bool = false
var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.2

var _ladders: Array[Area2D] = []
var _spawn_position: Vector2 = Vector2(80.0, 520.0)

@onready var _flashlight_glow: PointLight2D = get_node_or_null("FlashlightGlow")


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")
	_spawn_position = global_position


func is_near_ladder() -> bool:
	return is_on_ladder or _ladders.size() > 0


func _on_ladder_area_entered(area: Area2D = null) -> void:
	is_on_ladder = true
	if area and not _ladders.has(area):
		_ladders.append(area)


func _on_ladder_area_exited(area: Area2D = null) -> void:
	if area:
		_ladders.erase(area)
	if _ladders.is_empty():
		is_on_ladder = false
		stop_climbing()


func enter_ladder(ladder: Area2D) -> void:
	_on_ladder_area_entered(ladder)


func exit_ladder(ladder: Area2D) -> void:
	_on_ladder_area_exited(ladder)


func start_climbing() -> void:
	if is_near_ladder():
		is_on_ladder = true
		is_climbing = true


func stop_climbing() -> void:
	is_climbing = false
	set_collision_mask_value(1, true)


func apply_climb_direction(vertical_dir: float) -> void:
	velocity.y = vertical_dir * climb_speed
	# Desactiva únicamente la máscara de pisos superiores (One-Way, capa 1) al moverse
	# verticalmente en la escalera; la planta baja sólida (capa 4 / bit 8) sigue activa.
	if abs(vertical_dir) > 0.1:
		set_collision_mask_value(1, false)
	else:
		set_collision_mask_value(1, true)


func _has_ladder_extending_above() -> bool:
	for ladder in _ladders:
		if is_instance_valid(ladder) and ladder.global_position.y < global_position.y - 8.0:
			return true
	return false


func _has_ladder_extending_below() -> bool:
	for ladder in _ladders:
		if is_instance_valid(ladder) and ladder.global_position.y > global_position.y - 36.0:
			return true
	return false


func _physics_process(delta: float) -> void:
	var vert_dir: float = Input.get_axis("ui_up", "ui_down")

	if is_near_ladder():
		if vert_dir < -0.1 and (is_climbing or not is_on_floor() or _has_ladder_extending_above()):
			is_climbing = true
		elif vert_dir > 0.1 and (is_climbing or _has_ladder_extending_below()):
			is_climbing = true
		elif is_climbing and is_on_floor() and abs(vert_dir) <= 0.1 and abs(Input.get_axis("ui_left", "ui_right")) > 0.1:
			stop_climbing()
	else:
		if is_climbing:
			stop_climbing()

	if is_climbing:
		apply_climb_direction(vert_dir)
	else:
		set_collision_mask_value(1, true)
		_apply_gravity(delta)
		_handle_jump()

	_handle_movement()
	_handle_attack()
	move_and_slide()
	_clamp_to_viewport()
	_tick_melee_timer(delta)

	if _flashlight_glow:
		_flashlight_glow.position.x = 12.0 * facing_direction

	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	_check_pit_boundary()


func _apply_gravity(delta: float) -> void:
	if is_climbing:
		velocity.y = 0.0
		return
	super._apply_gravity(delta)


func _handle_jump() -> void:
	if is_climbing:
		return
	super._handle_jump()


func _check_pit_boundary() -> void:
	var vp_size := get_viewport_rect().size
	var max_y: float = vp_size.y + 40.0 if vp_size.y > 0.0 else 640.0
	if global_position.y > max_y:
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

	velocity.y = -150.0
	velocity.x = -facing_direction * 100.0

	if _sprite:
		var tween := create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

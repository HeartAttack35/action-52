class_name UndergroundPlayer
extends FixedPlatformerController
## underground_player.gd
## Explorador / minero protagonista en Underground.
## Hereda de FixedPlatformerController y añade mecánicas de escalado en escaleras,
## suspensión de gravedad y gestión de daño/invulnerabilidad.

signal damage_taken

@export var climb_speed: float = 140.0

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
	return _ladders.size() > 0


func enter_ladder(ladder: Area2D) -> void:
	if not _ladders.has(ladder):
		_ladders.append(ladder)


func exit_ladder(ladder: Area2D) -> void:
	_ladders.erase(ladder)
	if _ladders.is_empty():
		stop_climbing()


func start_climbing() -> void:
	if is_near_ladder():
		is_climbing = true


func stop_climbing() -> void:
	is_climbing = false


func _physics_process(delta: float) -> void:
	_check_climbing_input()
	super._physics_process(delta)

	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	_check_pit_boundary()


func _check_climbing_input() -> void:
	if is_near_ladder():
		var vert_dir := Input.get_axis("ui_up", "ui_down")
		if abs(vert_dir) > 0.1:
			is_climbing = true
	else:
		if is_climbing:
			stop_climbing()


func apply_climb_direction(vertical_dir: float) -> void:
	velocity.y = vertical_dir * climb_speed


func _apply_gravity(delta: float) -> void:
	if is_climbing:
		# En estado de escalada se anula temporalmente la gravedad y la velocidad
		# vertical pasa a ser controlada directamente por el input del jugador
		var vertical_dir := Input.get_axis("ui_up", "ui_down")
		apply_climb_direction(vertical_dir)
		return
	super._apply_gravity(delta)


func _handle_jump() -> void:
	if is_climbing:
		return
	# Si está parado sobre el suelo pero superpuesto con una escalera y presiona arriba,
	# prioriza comenzar a escalar
	if is_near_ladder() and Input.is_action_pressed("ui_up"):
		start_climbing()
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

	# Pequeño retroceso al recibir impacto
	velocity.y = -150.0
	velocity.x = -facing_direction * 100.0

	# Efecto visual de parpadeo de invulnerabilidad
	if _sprite:
		var tween = create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

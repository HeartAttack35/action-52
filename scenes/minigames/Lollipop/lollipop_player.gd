class_name LollipopPlayer
extends FixedPlatformerController
## lollipop_player.gd
## Controlador del héroe con paleta del minijuego "Lollipop".
## Hereda de FixedPlatformerController (PlatformerPlayerBase) usando ataque
## cuerpo a cuerpo (Area2D frontal temporal) en lugar de proyectiles,
## además de gestionar daño, invulnerabilidad y seguridad contra caídas.

signal damage_taken
signal melee_started

const INVULNERABILITY_DURATION: float = 1.2

var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
var _spawn_position: Vector2 = Vector2(400.0, 522.0)
var _swing_tween: Tween = null

@onready var _swing_sprite: Sprite2D = get_node_or_null("AttackArea/LollipopSwingSprite")


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")
	_spawn_position = global_position

	if _attack_area:
		_attack_area.add_to_group("player_melee")
		_attack_area.add_to_group("lollipop_attack")
		if not _attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			_attack_area.body_entered.connect(_on_attack_area_body_entered)
		if not _attack_area.area_entered.is_connected(_on_attack_area_area_entered):
			_attack_area.area_entered.connect(_on_attack_area_area_entered)

	if _swing_sprite:
		_swing_sprite.visible = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	# Protección de seguridad ante caídas fuera del área fija (800x600)
	var vp_size := get_viewport_rect().size
	var max_y: float = 640.0
	if vp_size.y > 0.0 and vp_size.y < 600.0:
		max_y = vp_size.y + 40.0
	if global_position.y > max_y:
		global_position = _spawn_position
		velocity = Vector2.ZERO
		take_damage()


func _apply_direction(direction: float) -> void:
	super._apply_direction(direction)
	# El flip_h del swing sprite se actualiza solo cuando no hay un arco activo,
	# para no interrumpir la animación en curso.
	if _swing_sprite and not (_swing_tween and _swing_tween.is_running()):
		_swing_sprite.flip_h = (facing_direction < 0.0)


func is_melee_active() -> bool:
	return use_melee and _attack_shape != null and not _attack_shape.disabled


func _start_melee() -> void:
	super._start_melee()
	melee_started.emit()

	if _swing_sprite and is_inside_tree():
		if _swing_tween and _swing_tween.is_valid():
			_swing_tween.kill()

		# Radio horizontal del arco (distancia frente al jugador)
		var reach_x: float = 32.0
		# Radio vertical del arco (altura sobre/bajo el jugador)
		var reach_y: float = 28.0

		# El arco va de arriba-centro → frente-abajo
		# Posición inicial: encima del jugador, levemente adelante
		var pos_start := Vector2(reach_x * 0.4 * facing_direction, -reach_y)
		# Posición media: al frente, a la misma altura que el jugador
		var pos_mid   := Vector2(reach_x * facing_direction, 0.0)
		# Posición final: adelante-abajo
		var pos_end   := Vector2(reach_x * 0.4 * facing_direction,  reach_y)

		# Rotación: de apuntar arriba-adelante → horizontal → abajo-adelante
		# El signo invierte según facing_direction para mantener coherencia visual
		var rot_start := -1.1 * facing_direction  # ~−63° apuntando arriba
		var rot_mid   :=  0.0                      # horizontal
		var rot_end   :=  1.1 * facing_direction   # ~+63° apuntando abajo

		var dur: float = maxf(melee_duration, 0.08)

		_swing_sprite.visible = true
		_swing_sprite.flip_h = (facing_direction < 0.0)
		_swing_sprite.position = pos_start
		_swing_sprite.rotation = rot_start

		# Primera mitad del arco: inicio → frente
		_swing_tween = create_tween().set_parallel(true)
		_swing_tween.set_ease(Tween.EASE_IN_OUT)
		_swing_tween.set_trans(Tween.TRANS_SINE)
		_swing_tween.tween_property(_swing_sprite, "position", pos_mid, dur * 0.5)
		_swing_tween.tween_property(_swing_sprite, "rotation", rot_mid, dur * 0.5)
		await _swing_tween.finished

		# Segunda mitad del arco: frente → abajo (misma curva continua)
		if _swing_sprite and is_inside_tree():
			_swing_tween = create_tween().set_parallel(true)
			_swing_tween.set_ease(Tween.EASE_IN_OUT)
			_swing_tween.set_trans(Tween.TRANS_SINE)
			_swing_tween.tween_property(_swing_sprite, "position", pos_end, dur * 0.5)
			_swing_tween.tween_property(_swing_sprite, "rotation", rot_end, dur * 0.5)


func _tick_melee_timer(delta: float) -> void:
	super._tick_melee_timer(delta)
	if _swing_sprite and (not _attack_shape or _attack_shape.disabled):
		if _swing_tween and _swing_tween.is_valid():
			_swing_tween.kill()
		_swing_sprite.visible = false
		_swing_sprite.position = Vector2.ZERO
		_swing_sprite.rotation = 0.0


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not is_melee_active():
		return
	if (body.is_in_group("enemy") or body.is_in_group("enemigo")) and body.has_method("hit"):
		body.hit()


func _on_attack_area_area_entered(area: Area2D) -> void:
	if not is_melee_active():
		return
	var enemy := area.get_parent()
	if enemy and (enemy.is_in_group("enemy") or enemy.is_in_group("enemigo")) and enemy.has_method("hit"):
		enemy.hit()


func take_damage() -> void:
	if is_invulnerable:
		return

	is_invulnerable = true
	_invulnerability_timer = INVULNERABILITY_DURATION
	GameManager.lose_life()
	damage_taken.emit()

	velocity.y = -160.0
	velocity.x = -facing_direction * 120.0

	if _sprite and is_inside_tree():
		var tween := create_tween().set_loops(4)
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.15)

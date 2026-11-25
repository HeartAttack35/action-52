class_name TheEvilEmpirePlayer
extends FixedPlatformerController
## the_evil_empire_player.gd
## Controlador del guerrero árabe protagonista de "The Evil Empire".
## Hereda de FixedPlatformerController (PlatformerPlayerBase.tscn) y utiliza un
## Area2D frontal temporal (~0.2s) simulando un tajo rápido de cimitarra,
## además de gestionar daño recibido, invulnerabilidad y caídas fuera del patio.

signal damage_taken
signal melee_started

const INVULNERABILITY_DURATION: float = 1.2
const SLASH_OFFSET_X: float = 28.0

var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0
var _spawn_position: Vector2 = Vector2(400.0, 521.0)
var _slash_tween: Tween = null

@onready var _slash_sprite: Sprite2D = get_node_or_null("AttackArea/ScimitarSlashSprite")


func _ready() -> void:
	super._ready()
	add_to_group("player")
	add_to_group("jugador")
	_spawn_position = global_position

	if _attack_area:
		_attack_area.add_to_group("player_melee")
		_attack_area.add_to_group("scimitar_attack")
		if not _attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			_attack_area.body_entered.connect(_on_attack_area_body_entered)
		if not _attack_area.area_entered.is_connected(_on_attack_area_area_entered):
			_attack_area.area_entered.connect(_on_attack_area_area_entered)

	if _slash_sprite:
		_slash_sprite.visible = false
		_slash_sprite.position = Vector2(SLASH_OFFSET_X * facing_direction, 0.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if _sprite:
				_sprite.modulate.a = 1.0

	# Seguridad ante caídas fuera del área fija (800x600)
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
	if _slash_sprite:
		_slash_sprite.flip_h = (facing_direction < 0.0)
		if not (_slash_tween and _slash_tween.is_running()):
			_slash_sprite.position.x = SLASH_OFFSET_X * facing_direction


func is_melee_active() -> bool:
	return use_melee and _attack_shape != null and not _attack_shape.disabled


func _start_melee() -> void:
	super._start_melee()
	melee_started.emit()

	if _slash_sprite and is_inside_tree():
		if _slash_tween and _slash_tween.is_valid():
			_slash_tween.kill()

		var reach_x: float = 32.0
		var reach_y: float = 24.0
		var pos_start := Vector2(reach_x * 0.45 * facing_direction, -reach_y)
		var pos_mid := Vector2(reach_x * facing_direction, 0.0)
		var pos_end := Vector2(reach_x * 0.45 * facing_direction, reach_y)

		var rot_start := -1.05 * facing_direction
		var rot_mid := 0.0
		var rot_end := 1.05 * facing_direction

		var dur: float = maxf(melee_duration, 0.08)

		_slash_sprite.visible = true
		_slash_sprite.flip_h = (facing_direction < 0.0)
		_slash_sprite.position = pos_start
		_slash_sprite.rotation = rot_start

		_slash_tween = create_tween()
		_slash_tween.set_ease(Tween.EASE_IN_OUT)
		_slash_tween.set_trans(Tween.TRANS_SINE)
		_slash_tween.set_parallel(true)
		_slash_tween.tween_property(_slash_sprite, "position", pos_mid, dur * 0.5)
		_slash_tween.tween_property(_slash_sprite, "rotation", rot_mid, dur * 0.5)
		_slash_tween.chain().set_parallel(true)
		_slash_tween.tween_property(_slash_sprite, "position", pos_end, dur * 0.5)
		_slash_tween.tween_property(_slash_sprite, "rotation", rot_end, dur * 0.5)


func _tick_melee_timer(delta: float) -> void:
	super._tick_melee_timer(delta)
	if _slash_sprite and (not _attack_shape or _attack_shape.disabled):
		if _slash_tween and _slash_tween.is_valid():
			_slash_tween.kill()
		_slash_sprite.visible = false
		_slash_sprite.position = Vector2(SLASH_OFFSET_X * facing_direction, 0.0)
		_slash_sprite.rotation = 0.0


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
	if is_invulnerable or GameManager.lives <= 0:
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

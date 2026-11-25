class_name TopDownController
extends CharacterBody2D
## TopDownController.gd
## Base 8-directional top-down controller. Extend or instance this scene in
## each minigame that needs 8-way movement and optional shooting.
## Connect shoot_requested to the parent scene for projectile spawning.

# ── Signals ───────────────────────────────────────────────────────────────────
signal shoot_requested(position: Vector2, direction: Vector2)

# ── Exports ───────────────────────────────────────────────────────────────────
@export var speed: float = 120.0
@export var rotate_sprite_to_direction: bool = false

# ── Node references ───────────────────────────────────────────────────────────
@onready var _sprite:         CanvasItem = get_node_or_null("AnimatedSprite2D") if has_node("AnimatedSprite2D") else (get_node_or_null("Sprite2D") if has_node("Sprite2D") else null)
@onready var _weapon_pivot:   Marker2D   = get_node_or_null("WeaponPivot")
@onready var _attack_origin:  Marker2D   = get_node_or_null("WeaponPivot/AttackOrigin")

# ── Private state ─────────────────────────────────────────────────────────────
var facing_direction: Vector2 = Vector2.RIGHT

# ── Movement ──────────────────────────────────────────────────────────────────

## _apply_input_vector is extracted from _handle_movement so tests can call it
## directly without an Input mock. Requirements 1.1–1.7, 2.1–2.3.
func _apply_input_vector(input: Vector2) -> void:
	if input == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	var dir := input.normalized()
	velocity = dir * speed
	facing_direction = dir
	if _weapon_pivot:
		_weapon_pivot.rotation = dir.angle()
	if _sprite:
		if rotate_sprite_to_direction:
			_sprite.rotation = dir.angle()
		elif "flip_h" in _sprite:
			_sprite.flip_h = dir.x < 0.0

func _handle_movement() -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_apply_input_vector(input)

## Clamps global_position to the visible viewport. Requirements 1.9.
func _clamp_to_viewport() -> void:
	var vp := get_viewport_rect().size
	if vp.x > 0.0:
		global_position.x = clamp(global_position.x, 0.0, vp.x)
		global_position.y = clamp(global_position.y, 0.0, vp.y)

## Emits shoot_requested when the "shoot" action is pressed. Requirements 3.1–3.3.
func _handle_shoot() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return
	var pos := _attack_origin.global_position if _attack_origin else global_position
	shoot_requested.emit(pos, facing_direction.normalized())

## Main physics loop — movement → slide → clamp → shoot. Requirements 1.8.
func _physics_process(_delta: float) -> void:
	_handle_movement()
	move_and_slide()
	_clamp_to_viewport()
	_handle_shoot()

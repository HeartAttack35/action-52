class_name FixedPlatformerController
extends CharacterBody2D
## fixed_platformer_controller.gd
## Base 2D platformer controller. Extend or instance this scene in each
## minigame that needs horizontal movement, jumping, and optional attacks.
## Connect shoot_requested to the parent scene for projectile spawning.

# ── Signals ───────────────────────────────────────────────────────────────────
signal shoot_requested(position: Vector2)

# ── Exports ───────────────────────────────────────────────────────────────────
@export var speed: float          = 120.0
@export var jump_velocity: float  = -280.0
@export var attack_scene: PackedScene = null
@export var use_melee: bool       = true
@export var use_projectile: bool  = false
@export var melee_duration: float = 0.2

# ── Node references ───────────────────────────────────────────────────────────
@onready var _sprite:       CanvasItem       = get_node_or_null("AnimatedSprite2D") if has_node("AnimatedSprite2D") else (get_node_or_null("Sprite2D") if has_node("Sprite2D") else null)
@onready var _attack_area:  Area2D           = get_node_or_null("AttackArea")
@onready var _attack_shape: CollisionShape2D = get_node_or_null("AttackArea/AttackAreaShape")
@onready var _origin:       Marker2D         = get_node_or_null("AttackOrigin")

# ── Private state ─────────────────────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _attack_timer: float = 0.0   # counts down when melee hitbox is active
var facing_direction: float = 1.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	if _attack_shape:
		_attack_shape.disabled = true

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_handle_attack()
	move_and_slide()
	_clamp_to_viewport()
	_tick_melee_timer(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity
	elif Input.is_action_just_released("ui_up") and velocity.y < 0.0:
		velocity.y *= 0.5

func _handle_movement() -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	_apply_direction(direction)

## _apply_direction is extracted from _handle_movement so tests can call it
## directly without simulating Input.  Requirement 3.1-3.4.
func _apply_direction(direction: float) -> void:
	velocity.x = direction * speed
	if direction == 0.0:
		return
	var dir_sign: float = 1.0 if direction > 0.0 else -1.0
	facing_direction = dir_sign
	if _sprite and "flip_h" in _sprite:
		_sprite.flip_h = (dir_sign < 0.0)
	if _origin:
		_origin.position.x = abs(_origin.position.x) * dir_sign
	if _attack_shape:
		_attack_shape.position.x = abs(_attack_shape.position.x) * dir_sign
	if _attack_area and _attack_area.position.x != 0.0:
		_attack_area.position.x = abs(_attack_area.position.x) * dir_sign

func _clamp_to_viewport() -> void:
	var vp_size := get_viewport_rect().size
	if vp_size.x > 0.0:
		global_position.x = clamp(
			global_position.x, 0.0, vp_size.x
		)

func _handle_attack() -> void:
	if not (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_accept")):
		return
	if use_melee:
		_start_melee()
	if use_projectile:
		var shoot_pos: Vector2 = _origin.global_position if _origin else global_position
		shoot_requested.emit(shoot_pos)

func _start_melee() -> void:
	if _attack_shape:
		_attack_shape.disabled = false
	_attack_timer = melee_duration

func _tick_melee_timer(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			if _attack_shape:
				_attack_shape.disabled = true

func get_facing_direction() -> float:
	return facing_direction

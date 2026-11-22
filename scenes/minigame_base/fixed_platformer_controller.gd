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
@onready var _sprite:       AnimatedSprite2D = $AnimatedSprite2D
@onready var _attack_area:  Area2D           = $AttackArea
@onready var _attack_shape: CollisionShape2D = $AttackArea/AttackAreaShape
@onready var _origin:       Marker2D         = $AttackOrigin

# ── Private state ─────────────────────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _attack_timer: float = 0.0   # counts down when melee hitbox is active

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
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
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

func _handle_movement() -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	_apply_direction(direction)

## _apply_direction is extracted from _handle_movement so tests can call it
## directly without simulating Input.  Requirement 3.1-3.4.
func _apply_direction(direction: float) -> void:
	velocity.x = direction * speed
	if direction > 0.0:
		_sprite.flip_h = false
		_origin.position.x = abs(_origin.position.x)
	elif direction < 0.0:
		_sprite.flip_h = true
		_origin.position.x = -abs(_origin.position.x)

func _clamp_to_viewport() -> void:
	global_position.x = clamp(
		global_position.x, 0.0, get_viewport_rect().size.x
	)

func _handle_attack() -> void:
	if not Input.is_action_just_pressed("ui_select"):
		return
	if use_melee:
		_start_melee()
	if use_projectile:
		shoot_requested.emit(_origin.global_position)

func _start_melee() -> void:
	_attack_shape.disabled = false
	_attack_timer = melee_duration

func _tick_melee_timer(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_shape.disabled = true

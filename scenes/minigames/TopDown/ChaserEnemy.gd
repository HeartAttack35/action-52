class_name ChaserEnemy
extends CharacterBody2D
## ChaserEnemy.gd
## Basic chaser enemy for top-down minigames.  Moves directly toward the
## player each physics frame.  Destroyed (with a score reward) when hit by
## a projectile that enters the HurtArea.

# ── Exports ───────────────────────────────────────────────────────────────────
@export var speed: float = 80.0
@export var player_ref: NodePath = NodePath("")

# ── Private state ─────────────────────────────────────────────────────────────
var _player: Node = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("enemies")
	if player_ref != NodePath(""):
		_player = get_node_or_null(player_ref)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	velocity = (_player.global_position - global_position).normalized() * speed
	move_and_slide()

# ── Signal handlers ───────────────────────────────────────────────────────────
func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		GameManager.add_score(10)
		queue_free()

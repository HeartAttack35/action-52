class_name TopDownProjectile
extends Area2D
## TopDownProjectile.gd
## Reusable projectile for top-down minigames.
## Set direction and speed before adding to the scene tree.
## Signals (body_entered, area_entered, screen_exited) are connected
## from TopDownProjectile.tscn — no manual connect needed.

# ── Exports ───────────────────────────────────────────────────────────────────
@export var direction: Vector2 = Vector2(1, 0)
@export var speed: float = 400.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta

# ── Signal handlers ───────────────────────────────────────────────────────────
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		queue_free()

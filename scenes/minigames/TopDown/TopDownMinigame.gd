class_name TopDownMinigame
extends MinigameBase
## TopDownMinigame.gd
## Wired template scene for top-down minigames. Extend this for any minigame
## that needs 8-directional movement, shooting, and chaser enemies.
##
## Requirements 8.2, 8.4, 8.5

# ── Exports ───────────────────────────────────────────────────────────────────
@export var projectile_scene: PackedScene

# ── Node references ───────────────────────────────────────────────────────────
@onready var _player: TopDownController = $TopDownPlayerBase

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_player.shoot_requested.connect(_on_shoot_requested)
	GameManager.lives_changed.connect(_on_lives_changed)

# ── Signal handlers ───────────────────────────────────────────────────────────

## Spawns a projectile at pos travelling in dir. Requirement 8.4.
func _on_shoot_requested(pos: Vector2, dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj: Node = projectile_scene.instantiate()
	proj.direction = dir
	proj.global_position = pos
	get_tree().current_scene.add_child(proj)

## Ends the minigame with "lose" when all lives are gone. Requirement 8.5.
func _on_lives_changed(new_lives: int) -> void:
	if new_lives <= 0:
		finish("lose")

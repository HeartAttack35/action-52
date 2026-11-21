extends MinigameBase
## tcfos.gd  (They Came from Outer Space)
## Escena principal. El jugador está fijo en el centro y rota 90° para
## disparar en 4 direcciones. Los enemigos entran desde cualquier borde
## moviéndose en trayectorias horizontales o diagonales.
##
## Curva de dificultad:
##   Cada RAMP_INTERVAL segundos se reduce el wait_time del EnemySpawner
##   según una interpolación exponencial entre SPAWN_MAX y SPAWN_MIN.
##   RAMP_STEPS pasos de RAMP_INTERVAL segundos = duración total de la rampa.

const LASER_SCENE: PackedScene = preload(
	"res://scenes/minigames/They Came from Outer Space/laser.tscn")
const ENEMY_SCENE: PackedScene = preload(
	"res://scenes/minigames/They Came from Outer Space/enemy.tscn")

const SPAWN_MAX: float    = 2.5   # intervalo inicial (s)
const SPAWN_MIN: float    = 0.35  # intervalo mínimo (s)
const RAMP_INTERVAL: float = 10.0 # cada cuántos segundos sube la dificultad
const RAMP_STEPS: int      = 7    # pasos hasta llegar a SPAWN_MIN (70 s total)

# Direcciones disponibles: horizontal pura y diagonales (no vertical pura)
# agrupadas por borde de aparición.
const DIRS_FROM_TOP:    Array = [Vector2( 1, 1), Vector2(-1, 1)]             # SE, SW
const DIRS_FROM_BOTTOM: Array = [Vector2( 1,-1), Vector2(-1,-1)]             # NE, NW
const DIRS_FROM_LEFT:   Array = [Vector2( 1, 0), Vector2( 1, 1), Vector2( 1,-1)]  # E, SE, NE
const DIRS_FROM_RIGHT:  Array = [Vector2(-1, 0), Vector2(-1, 1), Vector2(-1,-1)]  # W, SW, NW

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Timer    = $EnemySpawner
@onready var diff_ticker: Timer      = $DiffTicker
@onready var label_score: Label      = $HUD/LabelScore
@onready var label_lives: Label      = $HUD/LabelLives
@onready var label_diff: Label       = $HUD/LabelDiff

var _diff_step: int = 0


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	# Nave fija en el centro
	player.position = vp / 2.0
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d"  % GameManager.lives
	label_diff.text  = "Nivel: 1"
	enemy_spawner.wait_time = SPAWN_MAX


func _on_shoot_requested(shoot_pos: Vector2, dir: Vector2) -> void:
	var laser: Area2D = LASER_SCENE.instantiate()
	laser.position  = shoot_pos
	laser.setup(dir)       # configura dirección, hitbox y aspecto visual
	add_child(laser)


func _on_enemy_spawner_timeout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var enemy: Area2D = ENEMY_SCENE.instantiate()

	# Elegir borde aleatorio y dirección compatible
	var edge: int = randi() % 4   # 0=top 1=bottom 2=left 3=right
	var spawn_pos: Vector2
	var dir_pool: Array

	match edge:
		0:  # top
			spawn_pos = Vector2(randf_range(0.0, vp.x), -24.0)
			dir_pool  = DIRS_FROM_TOP
		1:  # bottom
			spawn_pos = Vector2(randf_range(0.0, vp.x), vp.y + 24.0)
			dir_pool  = DIRS_FROM_BOTTOM
		2:  # left
			spawn_pos = Vector2(-24.0, randf_range(0.0, vp.y))
			dir_pool  = DIRS_FROM_LEFT
		3:  # right
			spawn_pos = Vector2(vp.x + 24.0, randf_range(0.0, vp.y))
			dir_pool  = DIRS_FROM_RIGHT

	enemy.position  = spawn_pos
	enemy.direction = (dir_pool.pick_random() as Vector2).normalized()
	add_child(enemy)


func _on_diff_ticker_timeout() -> void:
	_diff_step = mini(_diff_step + 1, RAMP_STEPS)
	var t: float = float(_diff_step) / float(RAMP_STEPS)
	# Curva exponencial: SPAWN_MAX * (SPAWN_MIN/SPAWN_MAX)^t
	enemy_spawner.wait_time = SPAWN_MAX * pow(SPAWN_MIN / SPAWN_MAX, t)
	label_diff.text = "Nivel: %d" % (_diff_step + 1)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")

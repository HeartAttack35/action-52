extends MinigameBase
## shooting_gallery.gd
## Escena principal del minijuego Shooting Gallery.
## Orquesta el spawner de blancos, conecta al jugador y mantiene el HUD
## sincronizado con el estado de GameManager.
##
## Dificultad progresiva de enemigos:
##   - ENEMY_INTERVAL_MAX : intervalo inicial entre spawns (segundos)
##   - ENEMY_INTERVAL_MIN : intervalo mínimo alcanzado a los RAMP_DURATION s
##   - RAMP_DURATION       : segundos hasta alcanzar la dificultad máxima
## La curva es exponencial para que los primeros 10 s sean lentos y la
## pantalla se llene notablemente entre los 40-50 s.

const ENEMY_INTERVAL_MAX: float = 4.0   # spawn cada 4 s al inicio
const ENEMY_INTERVAL_MIN: float = 0.25  # spawn cada 0.25 s a los 50 s
const RAMP_DURATION: float       = 50.0 # segundos de rampa

const BULLET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/target.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/enemy.tscn")

@onready var player: CharacterBody2D = $Player
@onready var target_spawner: Timer = $TargetSpawner
@onready var enemy_spawner: Timer = $EnemySpawner
@onready var spawn_points: Node2D = $SpawnPoints
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives

var _elapsed: float = 0.0  # tiempo acumulado desde el inicio del minijuego


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(50.0, vp.y / 2.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d" % GameManager.lives
	# Arranca con el intervalo máximo
	enemy_spawner.wait_time = ENEMY_INTERVAL_MAX


func _process(delta: float) -> void:
	_elapsed += delta


## Devuelve el intervalo de spawn según la curva exponencial.
## t=0  → ENEMY_INTERVAL_MAX   (4 s)
## t=50 → ENEMY_INTERVAL_MIN  (0.25 s)
func _enemy_interval() -> float:
	var t: float = clamp(_elapsed / RAMP_DURATION, 0.0, 1.0)
	# Interpolación exponencial: interval = MAX * (MIN/MAX)^t
	return ENEMY_INTERVAL_MAX * pow(ENEMY_INTERVAL_MIN / ENEMY_INTERVAL_MAX, t)


func _on_shoot_requested(shoot_pos: Vector2, dir: Vector2) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.position = shoot_pos
	bullet.setup(dir)
	add_child(bullet)


func _on_target_spawner_timeout() -> void:
	var points: Array = spawn_points.get_children()
	if points.is_empty():
		return
	var marker: Marker2D = points.pick_random()
	var target: Area2D = TARGET_SCENE.instantiate()
	target.position = marker.global_position
	add_child(target)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")


func _on_enemy_spawner_timeout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var enemy: Area2D = ENEMY_SCENE.instantiate()
	# Aparece justo fuera del borde derecho, con Y aleatoria dentro de la pantalla.
	enemy.position = Vector2(vp.x + 24.0, randf_range(40.0, vp.y - 40.0))
	add_child(enemy)
	# Recalcula el intervalo y reinicia el timer con el nuevo valor
	enemy_spawner.wait_time = _enemy_interval()
	enemy_spawner.start()

extends MinigameBase
## beeps_and_blips.gd
## Escena principal del minijuego "Beeps and Blips".
## El jugador controla una nave minimalista en el eje horizontal y dispara hacia arriba a entidades abstractas.
## Los enemigos spawnean periódicamente con frecuencia creciente a lo largo del tiempo.
## Mantiene conexión estándar con las señales de GameManager y MinigameBase.

const ENEMY_INTERVAL_MAX: float = 2.5   # Intervalo inicial entre spawns (segundos)
const ENEMY_INTERVAL_MIN: float = 0.35  # Intervalo mínimo en máxima dificultad
const RAMP_DURATION: float      = 45.0  # Segundos hasta alcanzar la dificultad máxima

const BULLET_SCENE: PackedScene = preload("res://scenes/minigames/Beeps and Blips/bullet.tscn")
const ENEMY_SCENE: PackedScene  = preload("res://scenes/minigames/Beeps and Blips/enemy.tscn")

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Timer    = $EnemySpawner
@onready var label_score: Label      = $HUD/LabelScore
@onready var label_lives: Label      = $HUD/LabelLives

var _elapsed: float = 0.0


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	# Posición inicial: centrado horizontalmente en la parte inferior
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)

	# Conexión estándar con GameManager
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d" % GameManager.lives

	enemy_spawner.wait_time = ENEMY_INTERVAL_MAX
	enemy_spawner.start()


func _process(delta: float) -> void:
	_elapsed += delta


## Calcula el intervalo entre enemigos según una curva exponencial creciente.
func _enemy_interval() -> float:
	var t: float = clamp(_elapsed / RAMP_DURATION, 0.0, 1.0)
	return ENEMY_INTERVAL_MAX * pow(ENEMY_INTERVAL_MIN / ENEMY_INTERVAL_MAX, t)


func _on_shoot_requested(shoot_pos: Vector2) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.position = shoot_pos
	add_child(bullet)


func _on_enemy_spawner_timeout() -> void:
	_spawn_enemy()
	enemy_spawner.wait_time = _enemy_interval()
	enemy_spawner.start()


func _spawn_enemy() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var enemy: Area2D = ENEMY_SCENE.instantiate()
	var spawn_x: float = randf_range(30.0, vp.x - 30.0)
	enemy.position = Vector2(spawn_x, -25.0)
	add_child(enemy)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")

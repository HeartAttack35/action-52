extends MinigameBase
## dedant.gd
## Escena principal del minijuego Dedant.
## El jugador se posiciona en el borde inferior y dispara hacia arriba
## a las hormigas que caen desde lo alto de la pantalla.
## Si una hormiga alcanza el borde inferior, el jugador pierde una vida.
##
## Dificultad progresiva:
##   Cada WAVE_TICK_INTERVAL segundos se incrementa _wave_size en 1,
##   de modo que por cada disparo del AntSpawner aparecen más hormigas
##   simultáneamente. Las X se distribuyen uniformemente para evitar
##   solapamientos excesivos.

const WAVE_TICK_INTERVAL: float = 5.0  # segundos entre incrementos de oleada

const BULLET_SCENE: PackedScene = preload("res://scenes/minigames/Dedant/bullet.tscn")
const ANT_SCENE: PackedScene    = preload("res://scenes/minigames/Dedant/ant.tscn")

@onready var player: CharacterBody2D = $Player
@onready var ant_spawner: Timer      = $AntSpawner
@onready var wave_ticker: Timer      = $WaveTicker
@onready var label_score: Label      = $HUD/LabelScore
@onready var label_lives: Label      = $HUD/LabelLives
@onready var label_wave: Label       = $HUD/LabelWave

var _wave_size: int = 1  # hormigas que aparecen por disparo del spawner


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	# Jugador fijo en el borde inferior, centrado horizontalmente al inicio
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d"  % GameManager.lives
	label_wave.text  = "Oleada: %d" % _wave_size


func _on_shoot_requested(shoot_pos: Vector2) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.position = shoot_pos
	add_child(bullet)


func _on_ant_spawner_timeout() -> void:
	var vp_width: float = get_viewport_rect().size.x
	# Dividir el ancho en _wave_size columnas y tomar el centro de cada una,
	# con un pequeño jitter para que no caigan en fila perfecta.
	var slot_w: float = vp_width / float(_wave_size)
	for i in range(_wave_size):
		var ant: Area2D = ANT_SCENE.instantiate()
		var base_x: float = slot_w * i + slot_w / 2.0
		var jitter: float = randf_range(-slot_w * 0.25, slot_w * 0.25)
		ant.position = Vector2(clamp(base_x + jitter, 20.0, vp_width - 20.0), -20.0)
		add_child(ant)


func _on_wave_ticker_timeout() -> void:
	_wave_size += 1
	label_wave.text = "Oleada: %d" % _wave_size


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")

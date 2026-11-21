extends MinigameBase
## spread_fire.gd
## Escena principal de Spread-Fire.
## El jugador dispara en triple abanico contra naves enemigas que
## descienden en diagonales variables desde la parte superior.
## Una colisión directa con el jugador provoca derrota inmediata.

const LASER_SCENE: PackedScene       = preload("res://scenes/minigames/Spread-Fire/laser.tscn")
const ENEMY_SHIP_SCENE: PackedScene  = preload("res://scenes/minigames/Spread-Fire/enemy_ship.tscn")

## Ángulo máximo de desviación diagonal de los enemigos (en grados).
## El ángulo real se elige al azar entre -MAX_DIAGONAL y +MAX_DIAGONAL.
const MAX_DIAGONAL_DEG: float = 35.0

@onready var player: CharacterBody2D  = $Player
@onready var enemy_spawner: Timer     = $EnemySpawner
@onready var label_score: Label       = $HUD/LabelScore
@onready var label_lives: Label       = $HUD/LabelLives


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d"  % GameManager.lives


func _on_shoot_requested(shoot_pos: Vector2, dir: Vector2) -> void:
	var laser: Area2D = LASER_SCENE.instantiate()
	laser.position  = shoot_pos
	laser.direction = dir
	add_child(laser)


func _on_enemy_spawner_timeout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var enemy: Area2D = ENEMY_SHIP_SCENE.instantiate()
	# X aleatoria en el borde superior
	enemy.position = Vector2(randf_range(20.0, vp.x - 20.0), -20.0)
	# Diagonal aleatoria: componente Y siempre positiva (desciende),
	# componente X varía entre -MAX_DIAGONAL y +MAX_DIAGONAL grados.
	var angle_deg: float = randf_range(-MAX_DIAGONAL_DEG, MAX_DIAGONAL_DEG)
	var rad: float = deg_to_rad(angle_deg)
	enemy.direction = Vector2(sin(rad), cos(rad))   # normalizado por construcción
	add_child(enemy)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")

extends MinigameBase
class_name HambosAdventures
## hambos_adventures.gd
## Escena principal del minijuego "Hambo's Adventures".
## Hambo escala una estructura industrial evitando bolas rodantes que descienden en zigzag.
## Gestiona el bucle de juego, la generación de obstáculos y las condiciones de victoria y derrota.

@onready var player: CharacterBody2D = $Player
@onready var tile_map: TileMap = $TileMap
@onready var ladders_container: Node2D = $Ladders
@onready var spawner: BallSpawner = $BallSpawner
@onready var goal: HamboGoal = $Goal
@onready var balls_container: Node2D = $Balls
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives
@onready var label_goal: Label = $HUD/LabelGoal
@onready var label_message: Label = $HUD/LabelMessage

var _game_over: bool = false


func _ready() -> void:
	_setup_girder_tilemap()

	# Configuración del jugador
	if player:
		player.position = Vector2(80.0, 500.0)

	# Conexiones con GameManager
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	# Conexión con la meta
	if goal:
		goal.reached.connect(_on_goal_reached)

	# Conexión con el spawner de bolas
	if spawner:
		spawner.ball_spawned.connect(_on_ball_spawned)

	_update_hud()
	if label_message:
		label_message.text = ""


## Dibuja la estructura de vigas metálicas en el TileMap
func _setup_girder_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# 1. Suelo base (y: 17, 18 -> y = 544px, 576px)
	for x in range(0, 26):
		tile_map.set_cell(0, Vector2i(x, 17), 0, Vector2i(0, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 0, Vector2i(0, 0))

	# 2. Nivel 1 de vigas (y: 13 -> y = 416px, x: 1 a 23)
	for x in range(1, 24):
		tile_map.set_cell(0, Vector2i(x, 13), 0, Vector2i(0, 0))

	# 3. Nivel 2 de vigas (y: 9 -> y = 288px, x: 2 a 24)
	for x in range(2, 25):
		tile_map.set_cell(0, Vector2i(x, 9), 0, Vector2i(0, 0))

	# 4. Nivel 3 de vigas superiores (y: 5 -> y = 160px, x: 2 a 23)
	for x in range(2, 24):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))


func _on_ball_spawned(_ball: RollingBall) -> void:
	# Bonus de supervivencia por cada bola esquivada en el flujo
	GameManager.add_score(50)


func _on_goal_reached(_body: Node2D) -> void:
	if _game_over:
		return
	_game_over = true
	if spawner:
		spawner.stop()
	_on_victory()


func _on_victory() -> void:
	if label_message:
		label_message.text = "¡VICTORIA! ¡HAMBO LLEGÓ A LA CIMA!"
	await get_tree().create_timer(2.0).timeout
	finish("win")


func _on_score_changed(_new_score: int) -> void:
	_update_hud()


func _on_lives_changed(new_lives: int) -> void:
	_update_hud()
	if new_lives <= 0 and not _game_over:
		_game_over = true
		if spawner:
			spawner.stop()
		if label_message:
			label_message.text = "¡SIN VIDAS! JUEGO TERMINADO"
		await get_tree().create_timer(1.5).timeout
		finish("lose")


func _update_hud() -> void:
	if label_score:
		label_score.text = "Puntos: %d" % GameManager.score
	if label_lives:
		label_lives.text = "Vidas: %d" % GameManager.lives
	if label_goal:
		label_goal.text = "Objetivo: ¡Alcanza la cima!"

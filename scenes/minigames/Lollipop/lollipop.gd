class_name Lollipop
extends MinigameBase
## lollipop.gd
## Escena principal del minijuego "Lollipop".
## Controla al héroe con paleta en un mundo de dulces con plataformas fijas,
## gestiona las criaturas hostiles, el HUD y las condiciones de victoria y derrota.

const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/Lollipop/enemy.tscn")

@onready var player: CharacterBody2D = $Player
@onready var tile_map: TileMap = $TileMap
@onready var enemies_container: Node2D = $Enemies
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives
@onready var label_enemies: Label = $HUD/LabelEnemies
@onready var label_message: Label = $HUD/LabelMessage

var remaining_enemies: int = 0
var _game_over: bool = false


func _ready() -> void:
	_setup_candy_tilemap()

	if player:
		player.position = Vector2(400.0, 522.0)

	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	if label_message:
		label_message.text = ""

	_setup_enemies()
	_update_hud()


## Construye el suelo inferior y los 3 niveles de plataformas flotantes de golosinas
func _setup_candy_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# 1. Suelo inferior temático (chocolate y menta, x: 0..25, y: 17..18 -> y=544px)
	for x in range(0, 26):
		tile_map.set_cell(0, Vector2i(x, 17), 0, Vector2i(1, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 0, Vector2i(1, 0))

	# 2. Nivel 1 de plataformas flotantes (oblea con glaseado fresa, y: 14 -> y=448px)
	for x in range(2, 8):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))
	for x in range(17, 23):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))

	# 3. Nivel 2 de plataformas flotantes (intermedias, y: 10 -> y=320px)
	for x in range(6, 11):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))
	for x in range(14, 19):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))

	# 4. Nivel 3 de plataformas flotantes (superiores, y: 6 -> y=192px)
	for x in range(1, 5):
		tile_map.set_cell(0, Vector2i(x, 6), 0, Vector2i(0, 0))
	for x in range(9, 16):
		tile_map.set_cell(0, Vector2i(x, 6), 0, Vector2i(0, 0))
	for x in range(20, 24):
		tile_map.set_cell(0, Vector2i(x, 6), 0, Vector2i(0, 0))


func _setup_enemies() -> void:
	var list: Array = enemies_container.get_children() if enemies_container else []
	remaining_enemies = 0
	for child in list:
		if child is CharacterBody2D or child.is_in_group("enemy"):
			remaining_enemies += 1
			if child.has_signal("defeated") and not child.defeated.is_connected(_on_enemy_defeated):
				child.defeated.connect(_on_enemy_defeated)

	_update_hud()


func _on_enemy_defeated(_enemy: CharacterBody2D) -> void:
	remaining_enemies -= 1
	_update_hud()

	if remaining_enemies <= 0 and not _game_over:
		_game_over = true
		_on_victory()


func _on_victory() -> void:
	if label_message:
		label_message.text = "¡VICTORIA! ¡MUNDO DULCE DESPEJADO!"
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		finish("win")


func _on_score_changed(_new_score: int) -> void:
	_update_hud()


func _on_lives_changed(new_lives: int) -> void:
	_update_hud()
	if new_lives <= 0 and not _game_over:
		_game_over = true
		if label_message:
			label_message.text = "¡SIN VIDAS! JUEGO TERMINADO"
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree():
			finish("lose")


func _update_hud() -> void:
	if label_score:
		label_score.text = "Puntos: %d" % GameManager.score
	if label_lives:
		label_lives.text = "Vidas: %d" % GameManager.lives
	if label_enemies:
		label_enemies.text = "Dulces: %d" % max(0, remaining_enemies)

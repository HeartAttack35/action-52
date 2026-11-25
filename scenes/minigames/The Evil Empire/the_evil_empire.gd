class_name TheEvilEmpire
extends MinigameBase
## the_evil_empire.gd
## Escena principal del minijuego "The Evil Empire".
## Controla al guerrero árabe con cimitarra en un palacio de arenisca con
## plataformas fijas sin scroll, gestiona el patrullaje de los guardias del
## imperio, el HUD y las condiciones de victoria y derrota.

const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/The Evil Empire/enemy.tscn")

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
	_setup_palace_tilemap()

	if player:
		player.position = Vector2(400.0, 521.0)

	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	if label_message:
		label_message.text = ""

	_setup_enemies()
	_update_hud()


## Construye el patio de arenisca, los muros laterales del palacio y las cornisas en 3 alturas
func _setup_palace_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# 1. Suelo del patio del palacio (arenisca, x: 0..24, y: 17..18 -> y=544px)
	for x in range(0, 25):
		tile_map.set_cell(0, Vector2i(x, 17), 0, Vector2i(1, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 0, Vector2i(1, 0))

	# 2. Muros laterales de arenisca delimitando la pantalla fija (x: 0 y x: 24)
	for y in range(0, 17):
		tile_map.set_cell(0, Vector2i(0, y), 0, Vector2i(2, 0))
		tile_map.set_cell(0, Vector2i(24, y), 0, Vector2i(2, 0))

	# 3. Nivel 1 de cornisas inferiores (y: 14 -> y=448px)
	for x in range(2, 8):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))
	for x in range(17, 23):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))

	# 4. Nivel 2 de balcones medios (y: 10 -> y=320px)
	for x in range(1, 6):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))
	for x in range(8, 17):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))
	for x in range(19, 24):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))

	# 5. Nivel 3 de almenas superiores (y: 6 -> y=192px)
	for x in range(2, 8):
		tile_map.set_cell(0, Vector2i(x, 6), 0, Vector2i(0, 0))
	for x in range(10, 15):
		tile_map.set_cell(0, Vector2i(x, 6), 0, Vector2i(0, 0))
	for x in range(17, 23):
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
		label_message.text = "¡VICTORIA! ¡EL IMPERIO HA CAÍDO!"
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
		label_enemies.text = "Guardias: %d" % max(0, remaining_enemies)

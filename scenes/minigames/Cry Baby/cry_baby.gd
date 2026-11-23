extends MinigameBase
## cry_baby.gd
## Escena principal del minijuego "Cry Baby".
## Controla al bebé protagonista en plataformas y estantes de guardería en pantalla fija,
## disparando chorros de leche a corta distancia desde su mamadera para neutralizar
## a los juguetes rebeldes antes de que hagan contacto físico.

const MILK_SQUIRT_SCENE: PackedScene = preload("res://scenes/minigames/Cry Baby/milk_squirt.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/Cry Baby/enemy.tscn")

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
	_setup_nursery_tilemap()

	# Configuración del bebé protagonista
	if player:
		player.position = Vector2(400.0, 500.0)
		player.shoot_requested.connect(_on_player_shoot_requested)

	# Conexión con GameManager
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	if label_message:
		label_message.text = ""

	_setup_enemies()
	_update_hud()


## Construye los estantes y bloques de juguete en el TileMap
func _setup_nursery_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# 1. Suelo base completo (celdas x: 0 a 25, y: 17 y 18 -> y: 544px a 576px)
	for x in range(0, 26):
		tile_map.set_cell(0, Vector2i(x, 17), 0, Vector2i(0, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 0, Vector2i(0, 0))

	# 2. Nivel 1 de estantes flotantes (inferiores: izquierda y derecha, y: 14 -> y: 448px)
	for x in range(2, 8):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))
	for x in range(17, 23):
		tile_map.set_cell(0, Vector2i(x, 14), 0, Vector2i(0, 0))

	# 3. Nivel 2 de estantes flotantes (medios: izquierda y derecha, y: 10 -> y: 320px)
	for x in range(6, 11):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))
	for x in range(14, 19):
		tile_map.set_cell(0, Vector2i(x, 10), 0, Vector2i(0, 0))

	# 4. Nivel 3 de estantes flotantes (superiores, y: 6 -> y: 192px)
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
			if child.has_signal("defeated"):
				child.defeated.connect(_on_enemy_defeated)

	_update_hud()


func _on_player_shoot_requested(shoot_pos: Vector2) -> void:
	if _game_over:
		return
	var scene_to_spawn: PackedScene = player.attack_scene if (player and player.attack_scene) else MILK_SQUIRT_SCENE
	var projectile: Node2D = scene_to_spawn.instantiate()
	projectile.global_position = shoot_pos
	var dir_x: float = player.facing_direction if ("facing_direction" in player) else 1.0
	if projectile.has_method("setup"):
		projectile.setup(Vector2(dir_x, 0.0))
	add_child(projectile)


func _on_enemy_defeated(_enemy: CharacterBody2D) -> void:
	remaining_enemies -= 1
	_update_hud()

	if remaining_enemies <= 0 and not _game_over:
		_game_over = true
		_on_victory()


func _on_victory() -> void:
	if label_message:
		label_message.text = "¡VICTORIA! ¡TODOS LOS JUGUETES RECOGIDOS!"
	await get_tree().create_timer(2.0).timeout
	finish("win")


func _on_score_changed(_new_score: int) -> void:
	_update_hud()


func _on_lives_changed(new_lives: int) -> void:
	_update_hud()
	if new_lives <= 0 and not _game_over:
		_game_over = true
		if label_message:
			label_message.text = "¡SIN VIDAS! HORA DE DORMIR"
		await get_tree().create_timer(1.5).timeout
		finish("lose")


func _update_hud() -> void:
	if label_score:
		label_score.text = "Puntos: %d" % GameManager.score
	if label_lives:
		label_lives.text = "Vidas: %d" % GameManager.lives
	if label_enemies:
		label_enemies.text = "Juguetes: %d" % max(0, remaining_enemies)

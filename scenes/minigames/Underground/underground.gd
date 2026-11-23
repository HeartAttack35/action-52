extends MinigameBase
## underground.gd
## Escena principal del minijuego "Underground".
## Controla el explorador en una caverna con plataformas fijas y escaleras,
## orquesta a las criaturas subterráneas y gestiona las condiciones de victoria y derrota.

const PICKAXE_SCENE: PackedScene = preload("res://scenes/minigames/Underground/pickaxe.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/Underground/enemy.tscn")

@onready var player: CharacterBody2D = $Player
@onready var tile_map: TileMap = $TileMap
@onready var enemies_container: Node2D = $Enemies
@onready var ladders_container: Node2D = $Ladders
@onready var gem: Area2D = get_node_or_null("Gem")
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives
@onready var label_enemies: Label = $HUD/LabelEnemies
@onready var label_message: Label = $HUD/LabelMessage

var remaining_enemies: int = 0
var _game_over: bool = false


func _ready() -> void:
	_setup_cavern_tilemap()

	# Configuración del jugador
	if player:
		player.position = Vector2(80.0, 500.0)
		player.shoot_requested.connect(_on_player_shoot_requested)

	# Conexión con GameManager
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	# Conexión con la gema objetivo
	if gem:
		gem.collected.connect(_on_gem_collected)

	# Contar e inicializar criaturas subterráneas
	_setup_enemies()

	_update_hud()
	if label_message:
		label_message.text = ""


## Construye las plataformas de piedra de la caverna en el TileMap
func _setup_cavern_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# 1. Suelo base de la cueva (y: 17, 18 -> y = 544px, 576px)
	for x in range(0, 26):
		tile_map.set_cell(0, Vector2i(x, 17), 0, Vector2i(0, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 0, Vector2i(0, 0))

	# 2. Nivel 1 de cornisas (y: 13 -> y = 416px)
	# Plataforma izquierda con abertura para Ladder 1 (abertura x: 10, 11)
	for x in range(0, 10):
		tile_map.set_cell(0, Vector2i(x, 13), 0, Vector2i(0, 0))
	for x in range(12, 26):
		tile_map.set_cell(0, Vector2i(x, 13), 0, Vector2i(0, 0))

	# 3. Nivel 2 de cornisas (y: 9 -> y = 288px)
	# Abertura para Ladder 2 (abertura x: 15, 16)
	for x in range(0, 15):
		tile_map.set_cell(0, Vector2i(x, 9), 0, Vector2i(0, 0))
	for x in range(17, 26):
		tile_map.set_cell(0, Vector2i(x, 9), 0, Vector2i(0, 0))

	# 4. Nivel 3 de cornisas superiores (y: 5 -> y = 160px)
	# Alcove para gema x: 1..6; abertura x: 7, 8 (Ladder 3); plataforma x: 9..20; abertura x: 21, 22 (Ladder 4)
	for x in range(1, 7):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))
	for x in range(9, 21):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))


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
	var scene_to_spawn: PackedScene = player.attack_scene if (player and player.attack_scene) else PICKAXE_SCENE
	var pick = scene_to_spawn.instantiate()
	pick.global_position = shoot_pos
	var dir_x: float = player.facing_direction if "facing_direction" in player else 1.0
	pick.setup(Vector2(dir_x, 0.0))
	add_child(pick)


func _on_enemy_defeated(_enemy: CharacterBody2D) -> void:
	remaining_enemies -= 1
	_update_hud()

	if remaining_enemies <= 0 and not _game_over:
		_game_over = true
		_on_victory("¡VICTORIA! ¡CRIATURAS ELIMINADAS!")


func _on_gem_collected(_player: Node2D) -> void:
	if not _game_over:
		_game_over = true
		_on_victory("¡VICTORIA! ¡GEMA DE LA CAVERNA ALCANZADA!")


func _on_victory(message: String) -> void:
	if label_message:
		label_message.text = message
	await get_tree().create_timer(2.0).timeout
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
		finish("lose")


func _update_hud() -> void:
	if label_score:
		label_score.text = "Puntos: %d" % GameManager.score
	if label_lives:
		label_lives.text = "Vidas: %d" % GameManager.lives
	if label_enemies:
		label_enemies.text = "Criaturas: %d" % max(0, remaining_enemies)

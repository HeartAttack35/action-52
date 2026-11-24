class_name Illuminator
extends MinigameBase
## illuminator.gd
## Escena principal del minijuego "Illuminator".
## Controla al protagonista en un edificio de varios pisos conectados por escaleras,
## administra el ciclo de luz y oscuridad (CanvasModulate + Timer cíclico + apagón total),
## y gestiona las condiciones de victoria y derrota.

signal darkness_changed(light_level: float)
signal blackout_triggered

const LIGHT_BEAM_SCENE: PackedScene = preload("res://scenes/minigames/Illuminator/light_beam.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/minigames/Illuminator/shadow_enemy.tscn")

@export var darkness_step: float = 0.07
@export var darkness_tick_interval: float = 1.0
@export var blackout_grace_duration: float = 3.5

@onready var player: CharacterBody2D = $Player
@onready var tile_map: TileMap = $TileMap
@onready var enemies_container: Node2D = $Enemies
@onready var ladders_container: Node2D = $Ladders
@onready var darkness_modulate: CanvasModulate = $DarknessModulate
@onready var darkness_overlay: ColorRect = $DarknessOverlay
@onready var darkness_timer: Timer = $DarknessTimer
@onready var blackout_timer: Timer = $BlackoutTimer
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives
@onready var label_enemies: Label = $HUD/LabelEnemies
@onready var label_light: Label = $HUD/LabelLight
@onready var light_bar: ProgressBar = $HUD/LightBar
@onready var label_message: Label = $HUD/LabelMessage

var remaining_enemies: int = 0
var light_level: float = 1.0
var is_total_darkness: bool = false
var _game_over: bool = false
var _light_tween: Tween = null


func _ready() -> void:
	_setup_building_tilemap()

	if player:
		player.position = Vector2(80.0, 520.0)
		player.shoot_requested.connect(_on_player_shoot_requested)

	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	_setup_enemies()
	_setup_darkness_cycle()
	_apply_light_visuals(false)
	_update_hud()

	if label_message:
		label_message.text = ""


## Construye los pisos y muros del edificio en el TileMap
func _setup_building_tilemap() -> void:
	if not tile_map:
		return

	tile_map.clear()

	# Muros exteriores laterales (source 1: sólido en capa 8)
	for y in range(1, 17):
		tile_map.set_cell(0, Vector2i(0, y), 1, Vector2i(0, 0))
		tile_map.set_cell(0, Vector2i(24, y), 1, Vector2i(0, 0))

	# Planta baja sólida (y: 17, 18 -> y = 544px..608px, source 1)
	for x in range(0, 25):
		tile_map.set_cell(0, Vector2i(x, 17), 1, Vector2i(0, 0))
		tile_map.set_cell(0, Vector2i(x, 18), 1, Vector2i(0, 0))

	# Piso 1 (y: 13 -> y = 416px, source 0 con One-Way Collision)
	for x in range(1, 11):
		tile_map.set_cell(0, Vector2i(x, 13), 0, Vector2i(0, 0))
	for x in range(13, 24):
		tile_map.set_cell(0, Vector2i(x, 13), 0, Vector2i(0, 0))

	# Piso 2 (y: 9 -> y = 288px, source 0 con One-Way Collision)
	for x in range(3, 22):
		tile_map.set_cell(0, Vector2i(x, 9), 0, Vector2i(0, 0))

	# Piso 3 (y: 5 -> y = 160px, source 0 con One-Way Collision)
	for x in range(1, 10):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))
	for x in range(11, 14):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))
	for x in range(15, 24):
		tile_map.set_cell(0, Vector2i(x, 5), 0, Vector2i(0, 0))


func _setup_enemies() -> void:
	var list: Array = enemies_container.get_children() if enemies_container else []
	remaining_enemies = 0
	for child in list:
		if child is CharacterBody2D or child.is_in_group("enemy"):
			remaining_enemies += 1
			if child.has_signal("defeated") and not child.defeated.is_connected(_on_enemy_defeated):
				child.defeated.connect(_on_enemy_defeated)
			if child.has_signal("light_restored") and not child.light_restored.is_connected(_on_shadow_light_restored):
				child.light_restored.connect(_on_shadow_light_restored)

	_update_hud()


func _setup_darkness_cycle() -> void:
	light_level = 1.0
	is_total_darkness = false

	if darkness_timer:
		darkness_timer.wait_time = darkness_tick_interval
		darkness_timer.one_shot = false
		if not darkness_timer.timeout.is_connected(_on_darkness_timer_timeout):
			darkness_timer.timeout.connect(_on_darkness_timer_timeout)
		darkness_timer.start()

	if blackout_timer:
		blackout_timer.wait_time = blackout_grace_duration
		blackout_timer.one_shot = true
		if not blackout_timer.timeout.is_connected(_on_blackout_timer_timeout):
			blackout_timer.timeout.connect(_on_blackout_timer_timeout)
		blackout_timer.stop()


func _on_darkness_timer_timeout() -> void:
	if _game_over:
		return

	light_level = maxf(0.0, light_level - darkness_step)
	_apply_light_visuals(true)
	_update_hud()
	darkness_changed.emit(light_level)

	if light_level <= 0.0 and not is_total_darkness:
		is_total_darkness = true
		if label_message:
			label_message.text = "¡OSCURIDAD TOTAL! ¡ELIMINA UNA SOMBRA!"
		if blackout_timer:
			blackout_timer.start()
		_apply_light_visuals(true)


func _on_blackout_timer_timeout() -> void:
	if _game_over or not is_total_darkness:
		return

	_game_over = true
	if darkness_timer:
		darkness_timer.stop()
	blackout_triggered.emit()

	if label_message:
		label_message.text = "¡OSCURIDAD TOTAL! EL EDIFICIO SE APAGÓ"
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		finish("lose")


func restore_light(amount: float = 1.0) -> void:
	if _game_over:
		return

	light_level = clampf(light_level + amount, 0.0, 1.0)
	is_total_darkness = false

	if blackout_timer:
		blackout_timer.stop()
	if darkness_timer:
		darkness_timer.start()

	if label_message and label_message.text.begins_with("¡OSCURIDAD TOTAL"):
		label_message.text = ""

	_apply_light_visuals(true)
	_update_hud()
	darkness_changed.emit(light_level)


func _apply_light_visuals(animate: bool = true) -> void:
	var target_modulate: Color
	var target_overlay_alpha: float

	if is_total_darkness:
		target_modulate = Color(0.02, 0.02, 0.04, 1.0)
		target_overlay_alpha = 0.90
	else:
		# Interpola desde claridad total (1.0) hasta penumbra profunda (0.06)
		var min_col := Color(0.06, 0.06, 0.12, 1.0)
		var max_col := Color(1.0, 1.0, 1.0, 1.0)
		target_modulate = min_col.lerp(max_col, light_level)
		target_overlay_alpha = (1.0 - light_level) * 0.25

	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()

	if animate and is_inside_tree():
		_light_tween = create_tween()
		_light_tween.set_parallel(true)
		if darkness_modulate:
			_light_tween.tween_property(darkness_modulate, "color", target_modulate, 0.35)
		if darkness_overlay:
			_light_tween.tween_property(darkness_overlay, "color:a", target_overlay_alpha, 0.35)
	else:
		if darkness_modulate:
			darkness_modulate.color = target_modulate
		if darkness_overlay:
			darkness_overlay.color.a = target_overlay_alpha


func _on_player_shoot_requested(shoot_pos: Vector2) -> void:
	if _game_over:
		return
	var scene_to_spawn: PackedScene = player.attack_scene if (player and player.attack_scene) else LIGHT_BEAM_SCENE
	var beam: Node2D = scene_to_spawn.instantiate()
	beam.global_position = shoot_pos
	var dir_x: float = player.facing_direction if ("facing_direction" in player) else 1.0
	if beam.has_method("setup"):
		beam.setup(Vector2(dir_x, 0.0))
	add_child(beam)


func _on_shadow_light_restored(amount: float) -> void:
	restore_light(amount)


func _on_enemy_defeated(_enemy: CharacterBody2D) -> void:
	remaining_enemies -= 1
	_update_hud()

	if remaining_enemies <= 0 and not _game_over:
		_game_over = true
		if darkness_timer:
			darkness_timer.stop()
		if blackout_timer:
			blackout_timer.stop()
		light_level = 1.0
		is_total_darkness = false
		_apply_light_visuals(true)
		_update_hud()
		_on_victory()


func _on_victory() -> void:
	if label_message:
		label_message.text = "¡VICTORIA! ¡EDIFICIO ILUMINADO!"
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		finish("win")


func _on_score_changed(_new_score: int) -> void:
	_update_hud()


func _on_lives_changed(new_lives: int) -> void:
	_update_hud()
	if new_lives <= 0 and not _game_over:
		_game_over = true
		if darkness_timer:
			darkness_timer.stop()
		if blackout_timer:
			blackout_timer.stop()
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
		label_enemies.text = "Sombras: %d" % max(0, remaining_enemies)
	var light_pct: int = int(round(light_level * 100.0))
	if label_light:
		label_light.text = "Luz: %d%%" % light_pct
	if light_bar:
		light_bar.value = light_pct

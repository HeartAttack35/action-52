extends MinigameBase
## shooting_gallery.gd
## Escena principal del minijuego Shooting Gallery.
## Orquesta el spawner de blancos, conecta al jugador y mantiene el HUD
## sincronizado con el estado de GameManager.

const BULLET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/target.tscn")

@onready var player: CharacterBody2D = $Player
@onready var target_spawner: Timer = $TargetSpawner
@onready var spawn_points: Node2D = $SpawnPoints
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d" % GameManager.lives


func _on_shoot_requested(shoot_pos: Vector2) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.position = shoot_pos
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

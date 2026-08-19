extends MinigameBase
## jupiter_scope.gd
## Escena principal del minijuego Jupiter Scope.
## Orquesta el spawner de meteoritos, conecta al jugador y mantiene el HUD
## sincronizado con el estado de GameManager.

const LASER_SCENE: PackedScene = preload("res://scenes/minigames/Jupiter Scope/laser.tscn")
const METEOR_SCENE: PackedScene = preload("res://scenes/minigames/Jupiter Scope/meteor.tscn")

@onready var player: CharacterBody2D = $Player
@onready var meteor_spawner: Timer = $MeteorSpawner
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d" % GameManager.lives


func _on_shoot_requested(shoot_pos: Vector2) -> void:
	var laser: Area2D = LASER_SCENE.instantiate()
	laser.position = shoot_pos
	add_child(laser)


func _on_meteor_spawner_timeout() -> void:
	var meteor: Area2D = METEOR_SCENE.instantiate()
	var vp_width: float = get_viewport_rect().size.x
	meteor.position = Vector2(randf_range(0.0, vp_width), -20.0)
	add_child(meteor)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")

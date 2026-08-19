extends Node
## game_manager.gd
## Autoload (singleton) que guarda el estado global compartido por todos los
## minijuegos: vidas, puntaje, y qué minijuego está activo.
## Registrar en Project Settings > Autoload como "GameManager".

signal lives_changed(new_lives: int)
signal score_changed(new_score: int)

var lives: int = 3
var score: int = 0
var current_minigame_id: String = ""


func reset_stats() -> void:
	lives = 3
	score = 0
	lives_changed.emit(lives)
	score_changed.emit(score)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		SceneManager.game_over()

extends Node
## scene_manager.gd
## Autoload (singleton) que centraliza el cambio de escenas: pasar del menú
## a un minijuego, y volver del minijuego al menú.
## Registrar en Project Settings > Autoload como "SceneManager".

const MAIN_MENU_PATH := "res://scenes/main_menu/main_menu.tscn"


func start_minigame(minigame_id: String) -> void:
	var info: Dictionary = MinigameRegistry.get_minigame(minigame_id)
	if info.is_empty():
		push_error("Minijuego no encontrado en el registro: %s" % minigame_id)
		return

	GameManager.current_minigame_id = minigame_id
	GameManager.reset_stats()
	get_tree().change_scene_to_file(info["scene"])


func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func game_over() -> void:
	# Punto de extensión: aquí podrías mostrar una pantalla de "Game Over"
	# antes de volver al menú, o guardar el puntaje más alto, etc.
	return_to_menu()

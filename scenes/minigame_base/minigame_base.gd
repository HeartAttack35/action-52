extends Node2D
class_name MinigameBase
## minigame_base.gd
## Clase base de la que deben heredar TODAS las escenas de minijuegos.
## Provee la señal y el método estándar para terminar un minijuego y
## volver al menú, además de una salida rápida con ESC/botón "back".
##
## Cómo usarla en un minijuego nuevo:
##   1. Crea tu escena (ej. jupiter_scope.tscn) con nodo raíz Node2D.
##   2. En el script de esa escena, cambia "extends Node2D" por
##      "extends MinigameBase".
##   3. Cuando el jugador gane o pierda, llama a finish("win") o finish("lose").

signal minigame_finished(result: String)


func finish(result: String) -> void:
	minigame_finished.emit(result)
	SceneManager.return_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		finish("quit")

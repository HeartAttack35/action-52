extends MinigameBase
## demo_minigame.gd
## Minijuego de prueba (placeholder). No es un juego real: solo existe
## para validar que el flujo Menú -> Minijuego -> Menú funciona antes
## de invertir tiempo en el primer minijuego real (Tier 1).


func _on_win_button_pressed() -> void:
	GameManager.add_score(100)
	finish("win")


func _on_lose_button_pressed() -> void:
	GameManager.lose_life()
	finish("lose")

extends Button
## minigame_button.gd
## Botón individual dentro de la grilla del menú. Recibe la info del
## minijuego (diccionario del registro) y se autoconfigura.

var minigame_id: String = ""


func setup(info: Dictionary) -> void:
	minigame_id = info.get("id", "")
	text = info.get("name", "???")

extends Control
## main_menu.gd
## Genera un botón por cada minijuego registrado en MinigameRegistry y
## arranca el minijuego correspondiente al presionarlo.

@onready var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer

const MINIGAME_BUTTON_SCENE := preload("res://scenes/main_menu/minigame_button.tscn")


func _ready() -> void:
	_populate_menu()


func _populate_menu() -> void:
	for game_info in MinigameRegistry.minigames:
		var btn: Button = MINIGAME_BUTTON_SCENE.instantiate()
		btn.setup(game_info)
		btn.pressed.connect(_on_minigame_selected.bind(game_info["id"]))
		grid.add_child(btn)


func _on_minigame_selected(id: String) -> void:
	SceneManager.start_minigame(id)

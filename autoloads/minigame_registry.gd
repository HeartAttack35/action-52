extends Node
## minigame_registry.gd
## Autoload (singleton) con el catálogo de minijuegos disponibles.
## Registrar en Project Settings > Autoload como "MinigameRegistry".
##
## Cada vez que termines un minijuego nuevo, agrega una entrada aquí.
## El menú principal se genera automáticamente a partir de esta lista,
## así que no necesitas tocar la escena del menú para agregar juegos.

var minigames: Array[Dictionary] = [
	{
		"id": "demo",
		"name": "Demo / Prueba",
		"scene": "res://scenes/minigames/demo_minigame/demo_minigame.tscn",
		"tier": 0,
	},
	{
		"id": "jupiter_scope",
		"name": "Jupiter Scope",
		"scene": "res://scenes/minigames/Jupiter Scope/jupiter_scope.tscn",
		"tier": 1,
	},
	{
		"id": "shooting_gallery",
		"name": "Shooting Gallery",
		"scene": "res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn",
		"tier": 1,
	},
	{
		"id": "dedant",
		"name": "Dedant",
		"scene": "res://scenes/minigames/Dedant/dedant.tscn",
		"tier": 1,
	},
	{
		"id": "spread_fire",
		"name": "Spread-Fire",
		"scene": "res://scenes/minigames/Spread-Fire/spread_fire.tscn",
		"tier": 1,
	},
	{
		"id": "tcfos",
		"name": "They Came from Outer Space",
		"scene": "res://scenes/minigames/They Came from Outer Space/tcfos.tscn",
		"tier": 1,
	},
	{
		"id": "beeps_and_blips",
		"name": "Beeps and Blips",
		"scene": "res://scenes/minigames/Beeps and Blips/BeepsAndBlips.tscn",
		"tier": 1,
	},
	{
		"id": "chill_out",
		"name": "Chill-Out",
		"scene": "res://scenes/minigames/Chill-Out/ChillOut.tscn",
		"tier": 2,
	},
	{
		"id": "french_baker",
		"name": "French Baker",
		"scene": "res://scenes/minigames/French Baker/FrenchBaker.tscn",
		"tier": 2,
	},
	{
		"id": "cry_baby",
		"name": "Cry Baby",
		"scene": "res://scenes/minigames/Cry Baby/CryBaby.tscn",
		"tier": 2,
	},
	{
		"id": "underground",
		"name": "Underground",
		"scene": "res://scenes/minigames/Underground/Underground.tscn",
		"tier": 2,
	},
]


func get_minigame(id: String) -> Dictionary:
	for game in minigames:
		if game.get("id") == id:
			return game
	return {}

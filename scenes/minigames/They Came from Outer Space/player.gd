extends CharacterBody2D
## player.gd  (They Came from Outer Space)
## Nave del jugador fija en el centro de la pantalla.
## Rota en incrementos rígidos de 90° con las flechas direccionales.
## El Marker2D "Crosshair" y "ShootPoint" rotan junto al nodo padre,
## por lo que siempre apuntan en la dirección de la nave.
##
## Rotaciones (Godot 2D, sprite apunta hacia arriba en rot=0):
##   ui_up    →  0        (arriba)
##   ui_right →  PI/2     (derecha)
##   ui_down  →  PI       (abajo)
##   ui_left  → -PI/2     (izquierda)

signal shoot_requested(position: Vector2, direction: Vector2)

# Tabla de rotaciones indexadas 0..3
const ROTATIONS: Array[float] = [0.0, PI / 2.0, PI, -PI / 2.0]

# Mapeo tecla → índice
const KEY_TO_INDEX: Dictionary = {
	"ui_up":    0,
	"ui_right": 1,
	"ui_down":  2,
	"ui_left":  3,
}

var _rot_index: int = 0   # arriba por defecto


func _process(_delta: float) -> void:
	# Rotación rígida
	for action in KEY_TO_INDEX:
		if Input.is_action_just_pressed(action):
			_rot_index = KEY_TO_INDEX[action]
			rotation = ROTATIONS[_rot_index]
			break

	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	# Dirección de disparo: "arriba" del sprite rotado → Vector2(0,-1).rotated(rotation)
	var dir: Vector2 = Vector2(0.0, -1.0).rotated(rotation)
	shoot_requested.emit($ShootPoint.global_position, dir)

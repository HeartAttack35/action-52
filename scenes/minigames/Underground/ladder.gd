class_name Ladder
extends Area2D
## ladder.gd
## Elemento de escenario que permite al explorador escalar verticalmente entre plataformas.
## Emite señales de entrada/salida y notifica al jugador para activar el modo de escalada.

signal ladder_entered(body: Node2D)
signal ladder_exited(body: Node2D)


func _ready() -> void:
	add_to_group("ladder")
	add_to_group("escalera")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder(self)
	ladder_entered.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder(self)
	ladder_exited.emit(body)

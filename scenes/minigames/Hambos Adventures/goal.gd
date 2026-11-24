class_name HamboGoal
extends Area2D
## goal.gd
## Meta / Cima de la estructura en "Hambo's Adventures".
## Cuando Hambo alcanza la cima y entra en esta área, se activa la condición de victoria.

signal reached(player: Node2D)

@export var bonus_score: int = 500

var _is_triggered: bool = false


func _ready() -> void:
	add_to_group("goal")
	add_to_group("meta")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _is_triggered:
		return
	if body.is_in_group("player") or body is HamboPlayer:
		_is_triggered = true
		GameManager.add_score(bonus_score)
		reached.emit(body)

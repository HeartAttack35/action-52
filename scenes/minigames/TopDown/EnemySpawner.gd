class_name EnemySpawner
extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var player_path: NodePath = NodePath("")


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


func _on_timer_timeout() -> void:
	if enemy_scene == null:
		return

	var markers: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			markers.append(child)

	if markers.is_empty():
		return

	var spawn_point: Marker2D = markers[randi() % markers.size()]
	var enemy: Node = enemy_scene.instantiate()
	enemy.player_ref = player_path
	enemy.global_position = spawn_point.global_position
	get_parent().add_child(enemy)

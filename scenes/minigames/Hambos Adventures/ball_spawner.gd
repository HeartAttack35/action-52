class_name BallSpawner
extends Node2D
## ball_spawner.gd
## Generador de obstáculos situado en la plataforma superior de "Hambo's Adventures".
## Instancia bolas rodantes a intervalos regulares usando un nodo Timer.

signal ball_spawned(ball: RollingBall)

@export var ball_scene: PackedScene = preload("res://scenes/minigames/Hambos Adventures/rolling_ball.tscn")
@export var spawn_interval: float = 3.0
@export var initial_direction: float = 1.0
@export var initial_speed: float = 140.0
@export var auto_start: bool = true
@export var max_balls: int = 0 # 0 = ilimitado

@onready var timer: Timer = $Timer

var spawned_count: int = 0
var is_active: bool = false


func _ready() -> void:
	if not timer:
		timer = Timer.new()
		timer.name = "Timer"
		add_child(timer)

	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)

	if auto_start:
		start()


func start() -> void:
	is_active = true
	if timer:
		timer.wait_time = spawn_interval
		timer.start()


func stop() -> void:
	is_active = false
	if timer:
		timer.stop()


func _on_timer_timeout() -> void:
	if not is_active:
		return
	if max_balls > 0 and spawned_count >= max_balls:
		stop()
		return
	spawn_ball()


func spawn_ball() -> RollingBall:
	if not ball_scene:
		return null

	var ball = ball_scene.instantiate() as RollingBall
	if not ball:
		return null

	ball.global_position = global_position
	ball.setup(initial_direction, initial_speed)

	# Se añade como hijo del contenedor de bolas o del padre de este spawner
	var target_parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	var balls_container = target_parent.get_node_or_null("Balls") if target_parent else null
	if balls_container:
		balls_container.add_child(ball)
	elif target_parent:
		target_parent.add_child(ball)
	else:
		add_child(ball)

	spawned_count += 1
	ball_spawned.emit(ball)
	return ball

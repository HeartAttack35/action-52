extends GdUnitTestSuite
# Feature: cry-baby — Milk squirt projectile tests

const MILK_SQUIRT_SCENE = preload("res://scenes/minigames/Cry Baby/milk_squirt.tscn")


func test_milk_squirt_setup_and_groups() -> void:
	var squirt = MILK_SQUIRT_SCENE.instantiate()
	add_child(squirt)
	await get_tree().process_frame

	assert_bool(squirt.is_in_group("player_projectile")).is_true()
	assert_bool(squirt.is_in_group("milk_squirt")).is_true()
	assert_object(squirt.get_node("Sprite2D")).is_not_null()
	assert_object(squirt.get_node("CollisionShape2D")).is_not_null()
	assert_object(squirt.get_node("LifetimeTimer")).is_not_null()

	# Alcance deliberadamente corto (vida entre 0.2 y 0.3 segundos)
	var timer: Timer = squirt.get_node("LifetimeTimer")
	assert_bool(timer.wait_time <= 0.3).is_true()
	assert_bool(timer.wait_time >= 0.2).is_true()

	squirt.queue_free()


func test_milk_squirt_movement_and_deceleration() -> void:
	var squirt = MILK_SQUIRT_SCENE.instantiate()
	add_child(squirt)
	squirt.global_position = Vector2(100.0, 100.0)
	squirt.setup(Vector2.RIGHT)
	await get_tree().process_frame

	var initial_x: float = squirt.position.x
	var initial_speed: float = squirt.current_speed

	squirt._physics_process(0.1)

	assert_bool(squirt.position.x > initial_x).is_true()
	# Comportamiento distintivo: fuerte desaceleración
	assert_bool(squirt.current_speed < initial_speed).is_true()

	squirt.queue_free()


func test_milk_squirt_hits_enemy() -> void:
	var squirt = MILK_SQUIRT_SCENE.instantiate()
	add_child(squirt)

	var mock_enemy = CharacterBody2D.new()
	mock_enemy.add_to_group("enemy")
	var script = GDScript.new()
	script.source_code = "extends CharacterBody2D\nvar was_hit: bool = false\nfunc hit() -> void:\n\twas_hit = true\n"
	script.reload()
	mock_enemy.set_script(script)
	add_child(mock_enemy)

	squirt._on_body_entered(mock_enemy)

	assert_bool(mock_enemy.was_hit).is_true()

	mock_enemy.queue_free()

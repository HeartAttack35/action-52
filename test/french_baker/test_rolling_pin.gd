extends GdUnitTestSuite
# Feature: french-baker — Rolling pin projectile tests

const ROLLING_PIN_SCENE = preload("res://scenes/minigames/French Baker/rolling_pin.tscn")


func test_rolling_pin_setup_and_groups() -> void:
	var pin = ROLLING_PIN_SCENE.instantiate()
	add_child(pin)
	await get_tree().process_frame

	assert_bool(pin.is_in_group("player_projectile")).is_true()
	assert_bool(pin.is_in_group("utensil")).is_true()
	assert_object(pin.get_node("Sprite2D")).is_not_null()
	assert_object(pin.get_node("CollisionShape2D")).is_not_null()
	assert_object(pin.get_node("LifetimeTimer")).is_not_null()

	pin.queue_free()


func test_rolling_pin_movement_and_rotation() -> void:
	var pin = ROLLING_PIN_SCENE.instantiate()
	add_child(pin)
	pin.global_position = Vector2(100.0, 100.0)
	pin.setup(Vector2.RIGHT)
	await get_tree().process_frame

	var sprite: Sprite2D = pin.get_node("Sprite2D")
	var initial_rotation: float = sprite.rotation
	var initial_x: float = pin.position.x

	pin._physics_process(0.1)

	assert_bool(pin.position.x > initial_x).is_true()
	assert_bool(sprite.rotation != initial_rotation).is_true()

	pin.queue_free()


func test_rolling_pin_hits_enemy() -> void:
	var pin = ROLLING_PIN_SCENE.instantiate()
	add_child(pin)

	var enemy_hit_called = [false]
	var mock_enemy = CharacterBody2D.new()
	mock_enemy.add_to_group("enemy")
	mock_enemy.set_script(GDScript.new())
	# Se define método hit dinámico
	var script = GDScript.new()
	script.source_code = "extends CharacterBody2D\nvar was_hit: bool = false\nfunc hit() -> void:\n\twas_hit = true\n"
	script.reload()
	mock_enemy.set_script(script)
	add_child(mock_enemy)

	pin._on_body_entered(mock_enemy)

	assert_bool(mock_enemy.was_hit).is_true()

	mock_enemy.queue_free()

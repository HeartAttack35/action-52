extends GdUnitTestSuite
# Feature: hambos_adventures — Ball spawner obstacle generator tests

const SPAWNER_SCENE = preload("res://scenes/minigames/Hambos Adventures/ball_spawner.tscn")


func test_spawner_properties_and_nodes() -> void:
	var spawner = SPAWNER_SCENE.instantiate()
	add_child(spawner)
	await get_tree().process_frame

	assert_bool(spawner is BallSpawner).is_true()
	assert_object(spawner.ball_scene).is_not_null()
	assert_float(spawner.spawn_interval).is_equal(3.0)
	assert_float(spawner.initial_direction).is_equal(1.0)
	assert_float(spawner.initial_speed).is_equal(140.0)

	var timer = spawner.get_node_or_null("Timer")
	assert_object(timer).is_not_null()

	spawner.queue_free()


func test_spawner_spawn_ball_instance_and_signal() -> void:
	var spawner = SPAWNER_SCENE.instantiate()
	add_child(spawner)
	await get_tree().process_frame

	var signal_data := {"received": false, "ball": null}

	spawner.ball_spawned.connect(func(b: RollingBall):
		signal_data["received"] = true
		signal_data["ball"] = b
	)

	var ball = spawner.spawn_ball()
	assert_object(ball).is_not_null()
	assert_bool(signal_data["received"]).is_true()
	assert_object(signal_data["ball"]).is_equal(ball)
	assert_int(spawner.spawned_count).is_equal(1)
	assert_float(ball.direction).is_equal(1.0)

	spawner.queue_free()
	if ball and is_instance_valid(ball):
		ball.queue_free()


func test_spawner_start_stop() -> void:
	var spawner = SPAWNER_SCENE.instantiate()
	add_child(spawner)
	await get_tree().process_frame

	spawner.stop()
	assert_bool(spawner.is_active).is_false()

	spawner.start()
	assert_bool(spawner.is_active).is_true()

	spawner.queue_free()

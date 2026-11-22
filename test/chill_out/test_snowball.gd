extends GdUnitTestSuite
# Feature: chill-out — Snowball projectile tests

const SNOWBALL_SCENE = preload("res://scenes/minigames/Chill-Out/snowball.tscn")


func test_snowball_shape_and_nodes() -> void:
	var snowball = SNOWBALL_SCENE.instantiate()
	add_child(snowball)
	await get_tree().process_frame

	assert_bool(snowball is Area2D).is_true()
	var col: CollisionShape2D = snowball.get_node("CollisionShape2D")
	assert_object(col.shape).is_not_null()
	assert_bool(col.shape is CircleShape2D).is_true()

	var timer: Timer = snowball.get_node("LifetimeTimer")
	assert_float(timer.wait_time).is_equal(1.2)
	assert_bool(timer.one_shot).is_true()

	snowball.queue_free()


func test_snowball_setup_player_vs_enemy() -> void:
	var player_ball = SNOWBALL_SCENE.instantiate()
	add_child(player_ball)
	player_ball.setup(Vector2.RIGHT, false)
	await get_tree().process_frame

	assert_bool(player_ball.is_in_group("player_snowball")).is_true()
	assert_bool(player_ball.is_in_group("enemy_snowball")).is_false()
	assert_vector2(player_ball.direction).is_equal(Vector2.RIGHT)
	player_ball.queue_free()

	var enemy_ball = SNOWBALL_SCENE.instantiate()
	add_child(enemy_ball)
	enemy_ball.setup(Vector2.LEFT, true)
	await get_tree().process_frame

	assert_bool(enemy_ball.is_in_group("enemy_snowball")).is_true()
	assert_bool(enemy_ball.is_in_group("player_snowball")).is_false()
	assert_vector2(enemy_ball.direction).is_equal(Vector2.LEFT)
	enemy_ball.queue_free()

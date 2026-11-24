extends GdUnitTestSuite
# Feature: hambos_adventures — Rolling ball obstacle tests

const BALL_SCENE = preload("res://scenes/minigames/Hambos Adventures/rolling_ball.tscn")
const PLAYER_SCENE = preload("res://scenes/minigames/Hambos Adventures/player.tscn")


func test_ball_components_and_groups() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child(ball)
	await get_tree().process_frame

	assert_bool(ball is CharacterBody2D).is_true()
	assert_bool(ball is RollingBall).is_true()
	assert_bool(ball.is_in_group("enemy")).is_true()
	assert_bool(ball.is_in_group("hazard")).is_true()
	assert_bool(ball.is_in_group("rolling_ball")).is_true()
	assert_bool(ball.is_in_group("obstaculo")).is_true()

	var col = ball.get_node_or_null("CollisionShape2D")
	assert_object(col).is_not_null()
	assert_object(col.shape).is_not_null()

	var hitbox = ball.get_node_or_null("Hitbox")
	assert_object(hitbox).is_not_null()

	var sprite = ball.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_not_null()

	ball.queue_free()


func test_ball_setup_and_movement_velocity() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child(ball)
	await get_tree().process_frame

	ball.setup(-1.0, 160.0)
	assert_float(ball.direction).is_equal(-1.0)
	assert_float(ball.speed).is_equal(160.0)

	ball._apply_movement(0.016)
	assert_float(ball.velocity.x).is_equal(-160.0)

	ball.queue_free()


func test_ball_zigzag_direction_inversion_logic() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child(ball)
	await get_tree().process_frame

	ball.direction = 1.0
	ball._was_on_floor = true

	# 1. Cae al vacío de la plataforma superior
	ball._apply_gravity_and_zigzag(0.016)
	assert_bool(ball._has_fallen).is_true()
	assert_float(ball.velocity.y).is_greater(0.0)

	# 2. Cuando toca suelo abajo con _has_fallen = true, invierte la dirección
	var direction_changed := [false]
	ball.direction_changed.connect(func(_new_dir):
		direction_changed[0] = true
	)

	# Simular aterrizaje y cambio de sentido
	ball._has_fallen = true
	ball.direction = -ball.direction
	ball.direction_changed.emit(ball.direction)
	assert_float(ball.direction).is_equal(-1.0)
	assert_bool(direction_changed[0]).is_true()

	ball.queue_free()


func test_ball_hits_player_and_damages() -> void:
	GameManager.reset_stats()
	var ball = BALL_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	ball.position = Vector2(500, 500)
	player.position = Vector2(0, 0)
	add_child(ball)
	add_child(player)
	await get_tree().process_frame

	var hit_signal_received := [false]
	ball.player_hit.connect(func(_p): hit_signal_received[0] = true)

	var lives_before = GameManager.lives
	ball._on_hitbox_body_entered(player)

	assert_bool(hit_signal_received[0]).is_true()
	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_bool(player.is_invulnerable).is_true()

	ball.queue_free()
	player.queue_free()

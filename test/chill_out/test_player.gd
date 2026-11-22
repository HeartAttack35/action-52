extends GdUnitTestSuite
# Feature: chill-out — Player configuration and controller tests

const PLAYER_SCENE = preload("res://scenes/minigames/Chill-Out/player.tscn")
const SNOWBALL_SCENE = preload("res://scenes/minigames/Chill-Out/snowball.tscn")


func test_player_controller_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_float(player.speed).is_equal(180.0)
	assert_float(player.jump_velocity).is_equal(-520.0)
	assert_bool(player.use_projectile).is_true()
	assert_bool(player.use_melee).is_false()
	assert_object(player.attack_scene).is_not_null()

	player.queue_free()


func test_player_groups_and_nodes() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player.is_in_group("player")).is_true()
	assert_bool(player.is_in_group("jugador")).is_true()

	var sprite = player.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_not_null()

	var col = player.get_node_or_null("CollisionShape2D")
	assert_object(col).is_not_null()
	assert_object(col.shape).is_not_null()

	var origin = player.get_node_or_null("AttackOrigin")
	assert_object(origin).is_not_null()

	player.queue_free()


func test_player_damage_and_invulnerability() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_bool(player.is_invulnerable).is_true()

	# Segundo impacto inmediato ignorado por invulnerabilidad
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	player.queue_free()


func test_player_collision_mask_includes_world_layer() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	# Capa 1 es la capa del mundo/suelo/plataformas
	assert_int(player.collision_mask & 1).is_equal(1)

	player.queue_free()


func test_player_pit_respawn_safety() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	# Simular caída accidental fuera de la pantalla
	player.global_position.y = 700.0
	player._physics_process(0.016)

	assert_vector2(player.global_position).is_equal(Vector2(400.0, 500.0))
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	player.queue_free()


func test_controls_jump_and_shoot_isolation() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var shot_fired := false
	player.shoot_requested.connect(func(_pos: Vector2): shot_fired = true)

	# 1. Simular ui_accept (Enter): debe disparar y NO saltar
	player.velocity.y = 0.0
	var ev_enter := InputEventAction.new()
	ev_enter.action = "ui_accept"
	ev_enter.pressed = true
	Input.parse_input_event(ev_enter)

	player._handle_attack()
	player._handle_jump()

	assert_bool(shot_fired).is_true()
	assert_float(player.velocity.y).is_equal(0.0)

	ev_enter.pressed = false
	Input.parse_input_event(ev_enter)
	player.queue_free()

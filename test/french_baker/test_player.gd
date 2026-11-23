extends GdUnitTestSuite
# Feature: french-baker — Player (French Baker) character tests

const PLAYER_SCENE = preload("res://scenes/minigames/French Baker/player.tscn")


func test_player_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_bool(player.is_in_group("player")).is_true()
	assert_bool(player.is_in_group("jugador")).is_true()

	assert_bool(player.use_projectile).is_true()
	assert_bool(player.use_melee).is_false()
	assert_object(player.attack_scene).is_not_null()
	assert_bool(player.jump_velocity <= -500.0).is_true()

	assert_object(player.get_node("Sprite2D")).is_not_null()
	assert_object(player.get_node("CollisionShape2D")).is_not_null()
	assert_object(player.get_node("AttackOrigin")).is_not_null()

	player.queue_free()


func test_player_damage_and_invulnerability() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	GameManager.reset_stats()
	var initial_lives = GameManager.lives

	var signal_box = [false]
	player.damage_taken.connect(func(): signal_box[0] = true)

	player.take_damage()

	assert_int(GameManager.lives).is_equal(initial_lives - 1)
	assert_bool(player.is_invulnerable).is_true()
	assert_bool(signal_box[0]).is_true()

	# Un segundo impacto durante invulnerabilidad no debe quitar vidas extra
	player.take_damage()
	assert_int(GameManager.lives).is_equal(initial_lives - 1)

	player.queue_free()

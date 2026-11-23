extends GdUnitTestSuite
# Feature: cry-baby — Player (Cry Baby) character tests

const PLAYER_SCENE = preload("res://scenes/minigames/Cry Baby/player.tscn")


func test_player_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_bool(player.is_in_group("player")).is_true()
	assert_bool(player.is_in_group("jugador")).is_true()
	assert_bool(player.is_in_group("baby")).is_true()

	assert_bool(player.use_projectile).is_true()
	assert_bool(player.use_melee).is_false()
	assert_object(player.attack_scene).is_not_null()

	# Físicas ajustadas para alcanzar plataformas más altas con buen arco de salto
	assert_bool(player.speed <= 150.0).is_true()
	assert_bool(player.jump_velocity <= -500.0).is_true()

	assert_object(player.get_node("Sprite2D")).is_not_null()
	assert_object(player.get_node("CollisionShape2D")).is_not_null()
	assert_object(player.get_node("AttackOrigin")).is_not_null()

	# Tamaño de colisión reducido para el bebé
	var shape: CapsuleShape2D = player.get_node("CollisionShape2D").shape as CapsuleShape2D
	assert_object(shape).is_not_null()
	assert_bool(shape.radius <= 14.0).is_true()
	assert_bool(shape.height <= 36.0).is_true()

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

	# Un segundo impacto durante invulnerabilidad no debe restar vidas extra
	player.take_damage()
	assert_int(GameManager.lives).is_equal(initial_lives - 1)

	player.queue_free()

extends GdUnitTestSuite
# Feature: illuminator — Player controller, ladder climbing, one-way collision and attack setup tests

const PLAYER_SCENE = preload("res://scenes/minigames/Illuminator/player.tscn")
const LADDER_SCENE = preload("res://scenes/minigames/Illuminator/Ladder.tscn")
const ILLUMINATOR_SCENE = preload("res://scenes/minigames/Illuminator/Illuminator.tscn")


func test_player_controller_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_bool(player is IlluminatorPlayer).is_true()
	assert_float(player.speed).is_equal(155.0)
	assert_float(player.jump_velocity).is_equal(-420.0)
	assert_float(player.climb_speed).is_equal(140.0)
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

	var glow = player.get_node_or_null("FlashlightGlow")
	assert_object(glow).is_not_null()

	player.queue_free()


func test_ladder_climbing_and_one_way_mask_toggle() -> void:
	var player = PLAYER_SCENE.instantiate()
	var ladder = LADDER_SCENE.instantiate()
	player.position = Vector2(0, 0)
	ladder.position = Vector2(500, 500)
	add_child(player)
	add_child(ladder)
	await get_tree().process_frame

	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_climbing).is_false()
	assert_bool(player.get_collision_mask_value(1)).is_true()
	assert_bool(player.get_collision_mask_value(4)).is_true()

	player.enter_ladder(ladder)
	assert_bool(player.is_near_ladder()).is_true()

	player.start_climbing()
	assert_bool(player.is_climbing).is_true()

	# Subir o bajar desactiva solo la máscara de pisos superiores (capa 1), manteniendo suelo base (capa 4)
	player.apply_climb_direction(-1.0)
	assert_float(player.velocity.y).is_equal(-140.0)
	assert_bool(player.get_collision_mask_value(1)).is_false()
	assert_bool(player.get_collision_mask_value(4)).is_true()

	player.apply_climb_direction(1.0)
	assert_float(player.velocity.y).is_equal(140.0)
	assert_bool(player.get_collision_mask_value(1)).is_false()
	assert_bool(player.get_collision_mask_value(4)).is_true()

	player.apply_climb_direction(0.0)
	assert_float(player.velocity.y).is_equal(0.0)
	assert_bool(player.get_collision_mask_value(1)).is_true()

	# Gravedad anulada durante escalada
	player.velocity.y = 0.0
	player._apply_gravity(0.016)
	assert_float(player.velocity.y).is_equal(0.0)

	# Salir de la escalera restaura todo
	player.exit_ladder(ladder)
	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_climbing).is_false()
	assert_bool(player.get_collision_mask_value(1)).is_true()

	player.queue_free()
	ladder.queue_free()


func test_one_way_platforms_and_ladder_reach_in_illuminator() -> void:
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var one_way_paths := [
		"Platforms/PlatformL1_Left/CollisionShape2D",
		"Platforms/PlatformL1_Right/CollisionShape2D",
		"Platforms/PlatformL2/CollisionShape2D",
		"Platforms/PlatformL3_Left/CollisionShape2D",
		"Platforms/PlatformL3_Center/CollisionShape2D",
		"Platforms/PlatformL3_Right/CollisionShape2D",
	]
	for p in one_way_paths:
		var col: CollisionShape2D = game.get_node(p)
		assert_bool(col.one_way_collision).is_true()

	# Planta baja sólida (no one-way)
	var floor_col: CollisionShape2D = game.get_node("Platforms/Floor/CollisionShape2D")
	assert_bool(floor_col.one_way_collision).is_false()

	# Escaleras alcanzan por encima de los pisos superiores
	var ladder1: Area2D = game.get_node("Ladders/Ladder1")
	var ladder3: Area2D = game.get_node("Ladders/Ladder3")
	var ladder5: Area2D = game.get_node("Ladders/Ladder5")
	assert_float(ladder1.position.y - 80.0).is_less(416.0)
	assert_float(ladder3.position.y - 80.0).is_less(288.0)
	assert_float(ladder5.position.y - 80.0).is_less(160.0)

	game.queue_free()


func test_player_damage_and_invulnerability() -> void:
	GameManager.reset_stats()
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_bool(player.is_invulnerable).is_true()

	# Segundo golpe ignorado durante invulnerabilidad
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	player.queue_free()

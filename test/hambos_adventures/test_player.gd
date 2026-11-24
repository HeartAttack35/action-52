extends GdUnitTestSuite
# Feature: hambos_adventures — Hambo player configuration and ladder mechanics tests

const PLAYER_SCENE = preload("res://scenes/minigames/Hambos Adventures/player.tscn")
const LADDER_SCENE = preload("res://scenes/minigames/Hambos Adventures/Ladder.tscn")
const HAMBOS_SCENE = preload("res://scenes/minigames/Hambos Adventures/HambosAdventures.tscn")


func test_player_controller_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_bool(player is HamboPlayer).is_true()
	assert_float(player.speed).is_equal(150.0)
	assert_float(player.jump_velocity).is_equal(-420.0)
	assert_float(player.climb_speed).is_equal(140.0)
	assert_bool(player.use_projectile).is_false()
	assert_bool(player.use_melee).is_false()

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

	player.queue_free()


func test_ladder_climbing_mechanics_and_gravity_nullification() -> void:
	var player = PLAYER_SCENE.instantiate()
	var ladder = LADDER_SCENE.instantiate()
	player.position = Vector2(0, 0)
	ladder.position = Vector2(500, 500)
	add_child(player)
	add_child(ladder)
	await get_tree().process_frame

	# 1. Inicialmente no está en escalera
	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_on_ladder).is_false()

	# 2. Entrar al rango de la escalera usando _on_ladder_area_entered
	player._on_ladder_area_entered(ladder)
	assert_bool(player.is_near_ladder()).is_true()
	assert_bool(player.is_on_ladder).is_true()

	# 3. Control de velocidad vertical de escalada y desactivación de colisión con el suelo
	player.apply_climb_direction(-1.0) # Subiendo
	assert_float(player.velocity.y).is_equal(-140.0)
	assert_bool(player.get_collision_mask_value(1)).is_false()

	player.apply_climb_direction(1.0) # Bajando
	assert_float(player.velocity.y).is_equal(140.0)
	assert_bool(player.get_collision_mask_value(1)).is_false()

	player.apply_climb_direction(0.0) # Quieto en la escalera
	assert_float(player.velocity.y).is_equal(0.0)
	assert_bool(player.get_collision_mask_value(1)).is_true()

	# 4. Comprobar anulación de gravedad durante la escalada
	player.velocity.y = 0.0
	player._apply_gravity(0.016)
	assert_float(player.velocity.y).is_equal(0.0)

	# 5. Salir de la escalera usando _on_ladder_area_exited restaura colisión con el suelo
	player._on_ladder_area_exited(ladder)
	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_on_ladder).is_false()
	assert_bool(player.get_collision_mask_value(1)).is_true()

	player.queue_free()
	ladder.queue_free()


func test_ladder_stop_climbing_and_exit_callbacks() -> void:
	var player = PLAYER_SCENE.instantiate()
	var ladder = LADDER_SCENE.instantiate()
	player.position = Vector2(0, 0)
	ladder.position = Vector2(500, 500)
	add_child(player)
	add_child(ladder)
	await get_tree().process_frame

	player.enter_ladder(ladder)
	assert_bool(player.is_on_ladder).is_true()

	# Detener escalada reactiva colisión
	player.stop_climbing()
	assert_bool(player.is_on_ladder).is_false()
	assert_bool(player.get_collision_mask_value(1)).is_true()

	player.queue_free()
	ladder.queue_free()


func test_ladder_dimensions_and_reach() -> void:
	var ladder = LADDER_SCENE.instantiate()
	add_child(ladder)
	await get_tree().process_frame

	var col = ladder.get_node_or_null("CollisionShape2D")
	assert_object(col).is_not_null()
	var shape: RectangleShape2D = col.shape as RectangleShape2D
	assert_object(shape).is_not_null()
	# La altura debe ser de al menos 160 px para sobrepasar el piso superior
	assert_float(shape.size.y).is_greater_equal(160.0)

	ladder.queue_free()


func test_one_way_platforms_in_hambos_adventures() -> void:
	var game = HAMBOS_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var plat1_col: CollisionShape2D = game.get_node("Platforms/PlatformL1/CollisionShape2D")
	var plat2_col: CollisionShape2D = game.get_node("Platforms/PlatformL2/CollisionShape2D")
	var plat3_col: CollisionShape2D = game.get_node("Platforms/PlatformL3/CollisionShape2D")

	assert_bool(plat1_col.one_way_collision).is_true()
	assert_bool(plat2_col.one_way_collision).is_true()
	assert_bool(plat3_col.one_way_collision).is_true()

	# Verificar que las escaleras sobrepasan la altura de cada plataforma
	var ladder1: Area2D = game.get_node("Ladders/Ladder1")
	var ladder2: Area2D = game.get_node("Ladders/Ladder2")
	var ladder3: Area2D = game.get_node("Ladders/Ladder3")

	# PlatformL1 top es y=416. Ladder1 top debe ser menor que 416 (más arriba)
	var l1_top = ladder1.position.y - 80.0
	assert_float(l1_top).is_less(416.0)

	# PlatformL2 top es y=288. Ladder2 top debe ser menor que 288 (más arriba)
	var l2_top = ladder2.position.y - 80.0
	assert_float(l2_top).is_less(288.0)

	# PlatformL3 top es y=160. Ladder3 top debe ser menor que 160 (más arriba)
	var l3_top = ladder3.position.y - 80.0
	assert_float(l3_top).is_less(160.0)

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

	# Segundo impacto ignorado mientras está invulnerable
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	player.queue_free()


func test_player_pit_respawn_safety() -> void:
	GameManager.reset_stats()
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	player.global_position.y = 700.0
	player._check_pit_boundary()

	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_float(player.global_position.y).is_less_equal(640.0)

	player.queue_free()

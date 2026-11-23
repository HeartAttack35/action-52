extends GdUnitTestSuite
# Feature: underground — Player configuration and ladder climbing tests

const PLAYER_SCENE = preload("res://scenes/minigames/Underground/player.tscn")
const LADDER_SCENE = preload("res://scenes/minigames/Underground/Ladder.tscn")


func test_player_controller_inheritance_and_properties() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_float(player.speed).is_equal(150.0)
	assert_float(player.jump_velocity).is_equal(-440.0)
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

	player.queue_free()


func test_ladder_climbing_mechanics_and_gravity_nullification() -> void:
	var player = PLAYER_SCENE.instantiate()
	var ladder = LADDER_SCENE.instantiate()
	add_child(player)
	add_child(ladder)
	await get_tree().process_frame

	# 1. Inicialmente no está en escalera
	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_climbing).is_false()

	# 2. Entrar al rango de la escalera
	player.enter_ladder(ladder)
	assert_bool(player.is_near_ladder()).is_true()

	# 3. Activar escalada
	player.start_climbing()
	assert_bool(player.is_climbing).is_true()

	# 4. Comprobar control directo de velocidad vertical
	player.apply_climb_direction(-1.0) # Subiendo
	assert_float(player.velocity.y).is_equal(-140.0)

	player.apply_climb_direction(1.0) # Bajando
	assert_float(player.velocity.y).is_equal(140.0)

	player.apply_climb_direction(0.0) # Quieto en la escalera
	assert_float(player.velocity.y).is_equal(0.0)

	# 5. Comprobar anulación de gravedad mientras escala
	var vel_before_gravity = player.velocity.y
	player._apply_gravity(0.016)
	assert_float(player.velocity.y).is_equal(0.0) # No se le suma _gravity * delta

	# 6. Salir de la escalera restaura el comportamiento normal
	player.exit_ladder(ladder)
	assert_bool(player.is_near_ladder()).is_false()
	assert_bool(player.is_climbing).is_false()

	# 7. Con escalada desactivada, la gravedad vuelve a actuar en el aire
	player.velocity = Vector2.ZERO
	# Aseguramos que no esté en el suelo para comprobar la aceleración de gravedad
	player._apply_gravity(0.1)
	assert_float(player.velocity.y).is_greater(0.0)

	player.queue_free()
	ladder.queue_free()


func test_player_damage_and_invulnerability() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_bool(player.is_invulnerable).is_true()

	# Segundo impacto ignorado por invulnerabilidad temporal
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	player.queue_free()


func test_player_pit_respawn_safety() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	player.global_position.y = 700.0
	player._physics_process(0.016)

	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_float(player.global_position.y).is_less(650.0)

	player.queue_free()

extends GdUnitTestSuite
# Feature: lollipop — Player controller, melee hitbox, facing direction and damage tests

const PLAYER_SCENE = preload("res://scenes/minigames/Lollipop/player.tscn")


func test_player_inheritance_and_melee_config() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player is FixedPlatformerController).is_true()
	assert_bool(player is LollipopPlayer).is_true()
	assert_bool(player.use_melee).is_true()
	assert_bool(player.use_projectile).is_false()
	assert_object(player.attack_scene).is_null()
	assert_float(player.melee_duration).is_between(0.15, 0.2)
	assert_bool(player.jump_velocity <= -500.0).is_true()

	player.queue_free()


func test_player_nodes_and_groups() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_bool(player.is_in_group("player")).is_true()
	assert_bool(player.is_in_group("jugador")).is_true()

	var sprite: Sprite2D = player.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_not_null()

	var col: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	assert_object(col).is_not_null()
	assert_object(col.shape).is_not_null()

	var attack_area: Area2D = player.get_node_or_null("AttackArea")
	assert_object(attack_area).is_not_null()
	assert_bool(attack_area.is_in_group("player_melee")).is_true()
	assert_bool(attack_area.is_in_group("lollipop_attack")).is_true()

	var attack_shape: CollisionShape2D = player.get_node_or_null("AttackArea/AttackAreaShape")
	assert_object(attack_shape).is_not_null()
	assert_object(attack_shape.shape).is_not_null()
	assert_bool(attack_shape.disabled).is_true()

	var swing_sprite: Sprite2D = player.get_node_or_null("AttackArea/LollipopSwingSprite")
	assert_object(swing_sprite).is_not_null()
	assert_object(swing_sprite.texture).is_not_null()
	assert_bool(swing_sprite.visible).is_false()

	player.queue_free()


func test_melee_activation_duration_and_facing_direction() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var attack_shape: CollisionShape2D = player.get_node("AttackArea/AttackAreaShape")
	var swing_sprite: Sprite2D = player.get_node("AttackArea/LollipopSwingSprite")

	# Al mirar a la izquierda, el hitbox frontal y el sprite se orientan a la izquierda
	player._apply_direction(-1.0)
	assert_float(player.facing_direction).is_equal(-1.0)
	assert_bool(attack_shape.position.x < 0.0).is_true()
	assert_bool(swing_sprite.position.x < 0.0).is_true()
	assert_bool(swing_sprite.flip_h).is_true()

	# Al mirar a la derecha, regresan a la derecha
	player._apply_direction(1.0)
	assert_float(player.facing_direction).is_equal(1.0)
	assert_bool(attack_shape.position.x > 0.0).is_true()
	assert_bool(swing_sprite.position.x > 0.0).is_true()
	assert_bool(swing_sprite.flip_h).is_false()

	# Al presionar ataque (ui_select): activa AttackAreaShape temporalmente y no emite proyectil
	var shoot_box := [false]
	player.shoot_requested.connect(func(_pos: Vector2): shoot_box[0] = true)

	Input.action_press("ui_select")
	player._handle_attack()
	Input.action_release("ui_select")

	assert_bool(shoot_box[0]).is_false()
	assert_bool(attack_shape.disabled).is_false()
	assert_bool(player.is_melee_active()).is_true()
	assert_bool(swing_sprite.visible).is_true()

	# A mitad de melee_duration sigue activo
	player._tick_melee_timer(player.melee_duration * 0.5)
	assert_bool(attack_shape.disabled).is_false()
	assert_bool(swing_sprite.visible).is_true()

	# Al cumplirse melee_duration se desactiva automáticamente
	player._tick_melee_timer(player.melee_duration * 0.6)
	assert_bool(attack_shape.disabled).is_true()
	assert_bool(player.is_melee_active()).is_false()
	assert_bool(swing_sprite.visible).is_false()

	player.queue_free()


func test_player_damage_invulnerability_and_pit_respawn() -> void:
	GameManager.reset_stats()
	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(400.0, 500.0)
	add_child(player)
	await get_tree().process_frame

	var lives_before: int = GameManager.lives
	var damage_box := [false]
	player.damage_taken.connect(func(): damage_box[0] = true)

	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)
	assert_bool(player.is_invulnerable).is_true()
	assert_bool(damage_box[0]).is_true()

	# Segundo golpe ignorado durante invulnerabilidad
	player.take_damage()
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	# Simular caída fuera de pantalla tras expirar invulnerabilidad
	player.is_invulnerable = false
	player.global_position.y = 700.0
	player._physics_process(0.016)
	assert_vector(player.global_position).is_equal(Vector2(400.0, 500.0))
	assert_int(GameManager.lives).is_equal(lives_before - 2)

	player.queue_free()

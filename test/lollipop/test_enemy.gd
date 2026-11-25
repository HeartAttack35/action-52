extends GdUnitTestSuite
# Feature: lollipop — Candy enemy patrol, melee defeat and player contact damage tests

const ENEMY_SCENE = preload("res://scenes/minigames/Lollipop/enemy.tscn")
const PLAYER_SCENE = preload("res://scenes/minigames/Lollipop/player.tscn")


func _make_test_floor(y_pos: float) -> StaticBody2D:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 7
	floor_body.position = Vector2(400.0, y_pos)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800.0, 32.0)
	col.shape = rect
	floor_body.add_child(col)
	return floor_body


func test_enemy_groups_and_components() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	assert_bool(enemy.is_in_group("enemy")).is_true()
	assert_bool(enemy.is_in_group("enemigo")).is_true()
	assert_bool(enemy.is_in_group("candy_enemy")).is_true()

	var sprite: Sprite2D = enemy.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_not_null()

	assert_object(enemy.get_node_or_null("CollisionShape2D")).is_not_null()
	assert_object(enemy.get_node_or_null("LedgeRayCast")).is_not_null()
	assert_object(enemy.get_node_or_null("WallRayCast")).is_not_null()
	assert_object(enemy.get_node_or_null("Hitbox")).is_not_null()

	enemy.queue_free()


func test_enemy_turn_around_updates_rays_and_sprite() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.initial_direction = 1.0
	add_child(enemy)
	await get_tree().process_frame

	assert_float(enemy.direction).is_equal(1.0)
	assert_bool(enemy.sprite.flip_h).is_false()
	assert_bool(enemy.ledge_ray.position.x > 0.0).is_true()
	assert_bool(enemy.wall_ray.target_position.x > 0.0).is_true()

	enemy._turn_around()
	assert_float(enemy.direction).is_equal(-1.0)
	assert_bool(enemy.sprite.flip_h).is_true()
	assert_bool(enemy.ledge_ray.position.x < 0.0).is_true()
	assert_bool(enemy.wall_ray.target_position.x < 0.0).is_true()

	enemy.queue_free()


func test_inactive_melee_does_not_defeat_enemy() -> void:
	GameManager.reset_stats()
	var player = PLAYER_SCENE.instantiate()
	var enemy = ENEMY_SCENE.instantiate()
	add_child(player)
	add_child(enemy)
	await get_tree().process_frame

	var initial_score: int = GameManager.score
	var attack_area: Area2D = player.get_node("AttackArea")
	assert_bool(player.get_node("AttackArea/AttackAreaShape").disabled).is_true()

	enemy._on_hitbox_area_entered(attack_area)

	assert_bool(enemy._is_dead).is_false()
	assert_int(GameManager.score).is_equal(initial_score)

	player.queue_free()
	enemy.queue_free()


func test_active_melee_collision_defeats_enemy_and_awards_score() -> void:
	GameManager.reset_stats()
	var floor_body := _make_test_floor(332.0)
	var player = PLAYER_SCENE.instantiate()
	var enemy = ENEMY_SCENE.instantiate()
	player.position = Vector2(200.0, 295.0)
	enemy.position = Vector2(236.0, 299.0)
	enemy.speed = 0.0

	add_child(floor_body)
	add_child(player)
	add_child(enemy)
	await get_tree().physics_frame

	player._apply_direction(1.0)
	var defeated_box := [false]
	enemy.defeated.connect(func(_e): defeated_box[0] = true)
	var initial_score: int = GameManager.score

	player._start_melee()
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_bool(defeated_box[0]).is_true()
	assert_bool(enemy._is_dead).is_true()
	assert_int(GameManager.score).is_equal(initial_score + 100)

	player.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	floor_body.queue_free()


func test_enemy_body_contact_damages_player() -> void:
	GameManager.reset_stats()
	var player = PLAYER_SCENE.instantiate()
	var enemy = ENEMY_SCENE.instantiate()
	add_child(player)
	add_child(enemy)
	await get_tree().process_frame

	var initial_lives: int = GameManager.lives
	enemy._on_hitbox_body_entered(player)

	assert_int(GameManager.lives).is_equal(initial_lives - 1)
	assert_bool(player.is_invulnerable).is_true()

	player.queue_free()
	enemy.queue_free()


func test_enemy_patrols_and_turns_at_ledge() -> void:
	var short_plat := StaticBody2D.new()
	short_plat.collision_layer = 1
	short_plat.collision_mask = 7
	short_plat.position = Vector2(200.0, 316.0)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96.0, 16.0)  # borde derecho en x = 248.0
	col.shape = rect
	short_plat.add_child(col)

	var enemy = ENEMY_SCENE.instantiate()
	enemy.initial_direction = 1.0
	enemy.speed = 120.0
	# Posición justo sobre la plataforma (top=308) y cerca del borde derecho (248)
	enemy.position = Vector2(226.0, 291.0)

	add_child(short_plat)
	add_child(enemy)

	# Ejecutar suficientes frames de física para tocar el suelo y alcanzar el borde
	for _i in 15:
		await get_tree().physics_frame

	assert_float(enemy.direction).is_equal(-1.0)

	enemy.queue_free()
	short_plat.queue_free()

extends GdUnitTestSuite
# Feature: french-baker — Enemy rebel food logic and defeat tests

const ENEMY_SCENE = preload("res://scenes/minigames/French Baker/enemy.tscn")


func test_enemy_groups_and_components() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	assert_bool(enemy.is_in_group("enemy")).is_true()
	assert_bool(enemy.is_in_group("enemigo")).is_true()
	assert_bool(enemy.is_in_group("rebel_food")).is_true()

	assert_object(enemy.get_node("Sprite2D")).is_not_null()
	assert_object(enemy.get_node("CollisionShape2D")).is_not_null()
	assert_object(enemy.get_node("LedgeRayCast")).is_not_null()
	assert_object(enemy.get_node("WallRayCast")).is_not_null()
	assert_object(enemy.get_node("Hitbox")).is_not_null()

	enemy.queue_free()


func test_enemy_defeat_adds_score_and_emits_signal() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	GameManager.reset_stats()
	var initial_score = GameManager.score
	var signal_box = [false]
	enemy.defeated.connect(func(_e): signal_box[0] = true)

	enemy.hit()

	assert_int(GameManager.score).is_equal(initial_score + 100)
	assert_bool(signal_box[0]).is_true()

	enemy.queue_free()


func test_enemy_turn_around() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	var initial_dir: float = enemy.direction
	enemy._turn_around()

	assert_float(enemy.direction).is_equal(-initial_dir)

	enemy.queue_free()

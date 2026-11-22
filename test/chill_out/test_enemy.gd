extends GdUnitTestSuite
# Feature: chill-out — Enemy rival logic and defeat tests

const ENEMY_SCENE = preload("res://scenes/minigames/Chill-Out/enemy.tscn")


func test_enemy_groups_and_components() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	assert_bool(enemy.is_in_group("enemy")).is_true()
	assert_bool(enemy.is_in_group("enemigo")).is_true()

	assert_object(enemy.get_node("LedgeRayCast")).is_not_null()
	assert_object(enemy.get_node("WallRayCast")).is_not_null()
	assert_object(enemy.get_node("ShootTimer")).is_not_null()
	assert_object(enemy.get_node("ShootPoint")).is_not_null()
	assert_object(enemy.get_node("Hitbox")).is_not_null()

	enemy.queue_free()


func test_enemy_defeat_adds_score_and_emits_signal() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	var initial_score = GameManager.score
	var defeated_signal_received = false
	enemy.defeated.connect(func(_e): defeated_signal_received = true)

	enemy.hit()

	assert_int(GameManager.score).is_equal(initial_score + 100)
	assert_bool(defeated_signal_received).is_true()

	enemy.queue_free()

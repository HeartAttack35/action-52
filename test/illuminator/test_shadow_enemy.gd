extends GdUnitTestSuite
# Feature: illuminator — Shadow enemy behavior, defeat and light restoration signal tests

const ENEMY_SCENE = preload("res://scenes/minigames/Illuminator/shadow_enemy.tscn")
const PLAYER_SCENE = preload("res://scenes/minigames/Illuminator/player.tscn")


func test_shadow_enemy_groups_and_components() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	assert_bool(enemy.is_in_group("enemy")).is_true()
	assert_bool(enemy.is_in_group("enemigo")).is_true()
	assert_bool(enemy.is_in_group("shadow")).is_true()

	assert_object(enemy.get_node_or_null("LedgeRayCast")).is_not_null()
	assert_object(enemy.get_node_or_null("WallRayCast")).is_not_null()
	assert_object(enemy.get_node_or_null("Hitbox")).is_not_null()

	enemy.queue_free()


func test_shadow_enemy_defeat_adds_score_and_emits_signals() -> void:
	GameManager.reset_stats()
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	var initial_score = GameManager.score
	var state := {"defeated": false, "restored": 0.0}
	enemy.defeated.connect(func(_e): state["defeated"] = true)
	enemy.light_restored.connect(func(amt): state["restored"] = amt)

	enemy.hit()
	# Segundo hit debe ser ignorado por el guardia _is_dead
	enemy.hit()

	assert_int(GameManager.score).is_equal(initial_score + 100)
	assert_bool(state["defeated"]).is_true()
	assert_float(state["restored"]).is_equal(1.0)

	enemy.queue_free()


func test_shadow_enemy_contact_damages_player() -> void:
	GameManager.reset_stats()
	var enemy = ENEMY_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	add_child(enemy)
	add_child(player)
	await get_tree().process_frame

	var lives_before = GameManager.lives
	enemy._on_hitbox_body_entered(player)
	assert_int(GameManager.lives).is_equal(lives_before - 1)

	enemy.queue_free()
	player.queue_free()

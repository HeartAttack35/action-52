extends GdUnitTestSuite
# Feature: underground — Pickaxe projectile tests

const PICKAXE_SCENE = preload("res://scenes/minigames/Underground/pickaxe.tscn")
const ENEMY_SCENE = preload("res://scenes/minigames/Underground/enemy.tscn")


func test_pickaxe_groups_and_components() -> void:
	var pickaxe = PICKAXE_SCENE.instantiate()
	add_child(pickaxe)
	await get_tree().process_frame

	assert_bool(pickaxe is Area2D).is_true()
	assert_bool(pickaxe.is_in_group("player_projectile")).is_true()
	assert_bool(pickaxe.is_in_group("pickaxe")).is_true()

	assert_object(pickaxe.get_node_or_null("CollisionShape2D")).is_not_null()
	assert_object(pickaxe.get_node_or_null("LifetimeTimer")).is_not_null()

	pickaxe.queue_free()


func test_pickaxe_movement() -> void:
	var pickaxe = PICKAXE_SCENE.instantiate()
	add_child(pickaxe)
	await get_tree().process_frame

	pickaxe.position = Vector2(100.0, 100.0)
	pickaxe.setup(Vector2.RIGHT)
	pickaxe._physics_process(0.1)

	# Se desplaza hacia la derecha a 320 px/s * 0.1s = 32px
	assert_float(pickaxe.position.x).is_greater(100.0)
	assert_float(pickaxe.position.y).is_equal(100.0)

	pickaxe.queue_free()


func test_pickaxe_hits_enemy() -> void:
	var pickaxe = PICKAXE_SCENE.instantiate()
	var enemy = ENEMY_SCENE.instantiate()
	add_child(pickaxe)
	add_child(enemy)
	await get_tree().process_frame

	var hit_emitted := false
	pickaxe.hit_enemy.connect(func(_e): hit_emitted = true)

	var score_before = GameManager.score
	pickaxe._on_body_entered(enemy)

	assert_bool(hit_emitted).is_true()
	assert_int(GameManager.score).is_equal(score_before + 100)

	pickaxe.queue_free()
	enemy.queue_free()

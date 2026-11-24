extends GdUnitTestSuite
# Feature: illuminator — Light beam projectile tests

const BEAM_SCENE = preload("res://scenes/minigames/Illuminator/light_beam.tscn")
const ENEMY_SCENE = preload("res://scenes/minigames/Illuminator/shadow_enemy.tscn")


func test_light_beam_groups_and_setup() -> void:
	var beam = BEAM_SCENE.instantiate()
	add_child(beam)
	await get_tree().process_frame

	assert_bool(beam.is_in_group("player_projectile")).is_true()
	assert_bool(beam.is_in_group("light_beam")).is_true()

	beam.setup(Vector2.LEFT)
	assert_vector(beam.direction).is_equal(Vector2.LEFT)
	assert_bool(beam.sprite.flip_h).is_true()

	beam.setup(Vector2.RIGHT)
	assert_vector(beam.direction).is_equal(Vector2.RIGHT)
	assert_bool(beam.sprite.flip_h).is_false()

	beam.queue_free()


func test_light_beam_moves_horizontally() -> void:
	var beam = BEAM_SCENE.instantiate()
	beam.position = Vector2(100.0, 200.0)
	beam.setup(Vector2.RIGHT)
	add_child(beam)
	await get_tree().process_frame

	var start_x: float = beam.position.x
	beam._physics_process(0.1)
	assert_float(beam.position.x).is_greater(start_x)

	beam.queue_free()


func test_light_beam_vaporizes_shadow_enemy() -> void:
	GameManager.reset_stats()
	var beam = BEAM_SCENE.instantiate()
	var enemy = ENEMY_SCENE.instantiate()
	add_child(beam)
	add_child(enemy)
	await get_tree().process_frame

	var state := {"defeated": false, "light": false}
	enemy.defeated.connect(func(_e): state["defeated"] = true)
	enemy.light_restored.connect(func(_amt): state["light"] = true)

	beam._on_body_entered(enemy)

	assert_bool(state["defeated"]).is_true()
	assert_bool(state["light"]).is_true()
	assert_bool(enemy._is_dead).is_true()
	assert_int(GameManager.score).is_equal(100)

	if is_instance_valid(beam):
		beam.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()

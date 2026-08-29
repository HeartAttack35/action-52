extends GdUnitTestSuite
# Feature: shooting-gallery — Scene initialization and configuration tests
# Validates: Requisitos 1.5, 4.1, 4.5, 6.5

const SG_SCENE = preload("res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn")


func test_target_spawner_config() -> void:
	var sg = SG_SCENE.instantiate()
	add_child(sg)
	await get_tree().process_frame

	var spawner: Timer = sg.get_node("TargetSpawner")
	assert_float(spawner.wait_time).is_equal(1.0)
	assert_bool(spawner.autostart).is_true()

	sg.queue_free()


func test_spawn_points_count() -> void:
	var sg = SG_SCENE.instantiate()
	add_child(sg)
	await get_tree().process_frame

	var spawn_points := sg.get_node("SpawnPoints")
	assert_int(spawn_points.get_children().size()).is_equal(5)

	sg.queue_free()


func test_player_initial_position() -> void:
	var sg = SG_SCENE.instantiate()
	add_child(sg)
	await get_tree().process_frame

	var vp: Vector2 = sg.get_viewport_rect().size
	var player := sg.get_node("Player")
	var expected := Vector2(vp.x / 2.0, vp.y - 50.0)
	assert_vector2(player.position).is_equal(expected)

	sg.queue_free()


func test_hud_initial_values() -> void:
	var sg = SG_SCENE.instantiate()
	add_child(sg)
	await get_tree().process_frame

	var label_score: Label = sg.get_node("HUD/LabelScore")
	var label_lives: Label = sg.get_node("HUD/LabelLives")

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)

	sg.queue_free()

extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 7: guard contra procesamiento doble en Target
# Valida: Requisito 3.5

const TARGET_SCENE = preload("res://scenes/minigames/Shooting Gallery/target.tscn")


func test_target_double_guard() -> void:
	# Propiedad 7: GameManager.add_score se llama exactamente una vez
	# aunque _on_area_entered sea disparado dos veces sobre el mismo target
	for i in 100:
		var target: Area2D = TARGET_SCENE.instantiate()
		add_child(target)

		# Create a mock area in the "proyectiles" group
		var mock_area := Area2D.new()
		mock_area.add_to_group("proyectiles")
		add_child(mock_area)

		# Record score before
		var score_before: int = GameManager.score

		# Call _on_area_entered twice — second call should be ignored by _dead guard
		target._on_area_entered(mock_area)
		target._on_area_entered(mock_area)

		# Score should have increased by exactly 10 (only one add_score call)
		assert_int(GameManager.score - score_before).is_equal(10)

		# Cleanup
		mock_area.queue_free()
		# target is already queued_free'd by _on_area_entered
		await get_tree().process_frame

extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 4: coexistencia de múltiples Balas

## Validates: Requisito 2.6

const BULLET_SCENE = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")

func test_multiple_bullets_coexist() -> void:
	# Propiedad 4: N bullets deben coexistir como hijos de un contenedor sin interferirse entre sí
	for n in range(2, 11):  # N from 2 to 10 inclusive
		var container := Node2D.new()
		add_child(container)

		# Instantiate N bullets
		for i in n:
			var bullet: Area2D = BULLET_SCENE.instantiate()
			bullet.position = Vector2(randf_range(0.0, 480.0), randf_range(50.0, 200.0))
			container.add_child(bullet)

		# Verify all N bullets exist
		var children := container.get_children()
		assert_int(children.size()).is_equal(n)

		# Verify none has been freed (is_instance_valid)
		for child in children:
			assert_bool(is_instance_valid(child)).is_true()

		# Cleanup
		container.queue_free()
		await get_tree().process_frame

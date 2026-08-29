extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 3: instanciación de Bala en la posición indicada
# Validates: Requisito 2.2

const BULLET_SCENE = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")


func test_bullet_instantiated_at_given_position() -> void:
	# Propiedad 3: la Bala debe tener la posición asignada inmediatamente tras add_child
	for i in 100:
		var pos := Vector2(randf_range(0.0, 480.0), randf_range(0.0, 270.0))
		var bullet: Area2D = BULLET_SCENE.instantiate()
		bullet.position = pos
		add_child(bullet)
		assert_vector2(bullet.position).is_equal(pos)
		bullet.queue_free()

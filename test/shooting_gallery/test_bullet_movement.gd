extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 2: movimiento uniforme de la Bala
# Valida: Requisito 2.3

const BULLET_SCENE = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")


func test_bullet_uniform_movement() -> void:
	# Propiedad 2: para cualquier delta > 0, position.y disminuye en exactamente SPEED * delta
	for i in 100:
		var delta := randf_range(0.001, 0.1)
		var bullet: Area2D = BULLET_SCENE.instantiate()
		add_child(bullet)
		var y_before := bullet.position.y
		bullet._physics_process(delta)
		assert_bool(is_equal_approx(bullet.position.y, y_before - 500.0 * delta)).is_true()
		bullet.queue_free()

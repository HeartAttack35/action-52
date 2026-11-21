extends GdUnitTestSuite
# Feature: beeps-and-blips — Bullet group and notifier tests

const BULLET_SCENE = preload("res://scenes/minigames/Beeps and Blips/bullet.tscn")


func test_bullet_is_in_proyectiles_group() -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	add_child(bullet)
	assert_bool(bullet.is_in_group("proyectiles")).is_true()
	bullet.queue_free()


func test_bullet_has_visible_on_screen_notifier() -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	add_child(bullet)
	var notifier = bullet.get_node("VisibleOnScreenNotifier2D")
	assert_object(notifier).is_not_null()
	bullet.queue_free()

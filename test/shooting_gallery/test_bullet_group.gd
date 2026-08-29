extends GdUnitTestSuite
# Feature: shooting-gallery — Bullet group membership test
# Validates: Requisito 2.5

const BULLET_SCENE = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")


func test_bullet_is_in_proyectiles_group() -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	add_child(bullet)
	assert_bool(bullet.is_in_group("proyectiles")).is_true()
	bullet.queue_free()

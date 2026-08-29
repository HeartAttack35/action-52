extends GdUnitTestSuite
# Feature: shooting-gallery — Target group membership test
# Validates: Requisito 3.4

const TARGET_SCENE = preload("res://scenes/minigames/Shooting Gallery/target.tscn")


func test_target_is_in_blancos_group() -> void:
	var target: Area2D = TARGET_SCENE.instantiate()
	add_child(target)
	assert_bool(target.is_in_group("blancos")).is_true()
	target.queue_free()

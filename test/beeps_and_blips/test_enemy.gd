extends GdUnitTestSuite
# Feature: beeps-and-blips — Enemy group and node tests

const ENEMY_SCENE = preload("res://scenes/minigames/Beeps and Blips/enemy.tscn")


func test_enemy_is_in_enemigos_group() -> void:
	var enemy: Area2D = ENEMY_SCENE.instantiate()
	add_child(enemy)
	assert_bool(enemy.is_in_group("enemigos")).is_true()
	enemy.queue_free()

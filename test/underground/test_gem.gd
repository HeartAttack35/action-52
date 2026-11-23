extends GdUnitTestSuite
# Feature: underground — Gem collectible / exit objective tests

const GEM_SCENE = preload("res://scenes/minigames/Underground/gem.tscn")
const PLAYER_SCENE = preload("res://scenes/minigames/Underground/player.tscn")


func test_gem_groups_and_components() -> void:
	var gem = GEM_SCENE.instantiate()
	add_child(gem)
	await get_tree().process_frame

	assert_bool(gem is Area2D).is_true()
	assert_bool(gem.is_in_group("gem")).is_true()
	assert_bool(gem.is_in_group("gema")).is_true()
	assert_bool(gem.is_in_group("exit")).is_true()

	assert_object(gem.get_node_or_null("CollisionShape2D")).is_not_null()
	assert_object(gem.get_node_or_null("Sprite2D")).is_not_null()

	gem.queue_free()


func test_gem_collection_adds_score_and_emits_signal() -> void:
	var gem = GEM_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	add_child(gem)
	add_child(player)
	await get_tree().process_frame

	var collected_emitted := false
	gem.collected.connect(func(_p): collected_emitted = true)

	var score_before = GameManager.score
	gem._on_body_entered(player)

	assert_bool(collected_emitted).is_true()
	assert_int(GameManager.score).is_equal(score_before + 500)

	player.queue_free()

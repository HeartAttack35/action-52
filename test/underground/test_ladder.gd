extends GdUnitTestSuite
# Feature: underground — Ladder element and signals test

const LADDER_SCENE = preload("res://scenes/minigames/Underground/Ladder.tscn")
const PLAYER_SCENE = preload("res://scenes/minigames/Underground/player.tscn")


func test_ladder_groups_and_components() -> void:
	var ladder = LADDER_SCENE.instantiate()
	add_child(ladder)
	await get_tree().process_frame

	assert_bool(ladder is Area2D).is_true()
	assert_bool(ladder.is_in_group("ladder")).is_true()
	assert_bool(ladder.is_in_group("escalera")).is_true()

	var shape = ladder.get_node_or_null("CollisionShape2D")
	assert_object(shape).is_not_null()
	assert_object(shape.shape).is_not_null()

	var sprite = ladder.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_not_null()

	ladder.queue_free()


func test_ladder_signals_and_player_callbacks() -> void:
	var ladder = LADDER_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	add_child(ladder)
	add_child(player)
	await get_tree().process_frame

	var entered_emitted := false
	var exited_emitted := false

	ladder.ladder_entered.connect(func(_b): entered_emitted = true)
	ladder.ladder_exited.connect(func(_b): exited_emitted = true)

	# Simular entrada del cuerpo del jugador
	ladder._on_body_entered(player)
	assert_bool(entered_emitted).is_true()
	assert_bool(player.is_near_ladder()).is_true()

	# Simular salida del cuerpo del jugador
	ladder._on_body_exited(player)
	assert_bool(exited_emitted).is_true()
	assert_bool(player.is_near_ladder()).is_false()

	ladder.queue_free()
	player.queue_free()

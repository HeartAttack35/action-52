extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 8: spawn de Blancos en posiciones válidas
# Valida: Requisitos 4.2, 4.3

const SG_SCENE = preload("res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn")

var _valid_positions: Array[Vector2] = [
	Vector2(48, 50), Vector2(144, 50), Vector2(240, 50), Vector2(336, 50), Vector2(432, 50)
]


func test_target_spawns_at_valid_positions() -> void:
	# Propiedad 8: la posición del Target instanciado debe coincidir con
	# la global_position de uno de los 5 Marker2D hijos de SpawnPoints.
	for i in 100:
		var sg = SG_SCENE.instantiate()
		add_child(sg)
		await get_tree().process_frame  # let _ready() run

		# Record children present before spawning
		var before_count := sg.get_child_count()

		# Trigger the spawner directly
		sg._on_target_spawner_timeout()
		await get_tree().process_frame

		# The new child should be at the end of the child list
		var after_children := sg.get_children()
		assert_int(after_children.size()).is_greater(before_count)

		# Find any child added after the snapshot
		var new_target: Node = null
		for idx in range(before_count, after_children.size()):
			new_target = after_children[idx]
			break

		assert_object(new_target).is_not_null()

		# Verify the target's position matches one of the 5 valid spawn points
		var pos: Vector2 = new_target.position
		var is_valid := false
		for valid_pos in _valid_positions:
			if pos.is_equal_approx(valid_pos):
				is_valid = true
				break

		assert_bool(is_valid).is_true()

		# Cleanup
		sg.queue_free()
		await get_tree().process_frame

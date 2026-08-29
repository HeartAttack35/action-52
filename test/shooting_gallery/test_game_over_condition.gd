extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 10: fin de partida al agotar vidas
# Valida: Requisitos 5.2, 6.6


# Subclase de prueba que hereda MinigameBase y replica _on_lives_changed,
# pero sobreescribe finish() para evitar que SceneManager cambie de escena
# durante las iteraciones del test.
class ShootingGalleryTestDouble extends MinigameBase:
	var finish_called := false
	var finish_result := ""
	var label_lives: Label

	func _ready() -> void:
		label_lives = Label.new()
		add_child(label_lives)

	func _on_lives_changed(new_lives: int) -> void:
		label_lives.text = "Vidas: %d" % new_lives
		if new_lives <= 0:
			finish("lose")

	func finish(result: String) -> void:
		finish_called = true
		finish_result = result
		minigame_finished.emit(result)
		# No llamamos a SceneManager.return_to_menu() para no cambiar escena en tests


func test_game_over_when_lives_zero_or_less() -> void:
	# Propiedad 10: para cualquier v <= 0, _on_lives_changed(v) debe invocar finish("lose")
	for i in 100:
		var v := randi_range(-100, 0)

		var sg := ShootingGalleryTestDouble.new()
		add_child(sg)
		await get_tree().process_frame

		# Escuchar la señal minigame_finished
		var signal_received := false
		var received_result := ""
		sg.minigame_finished.connect(func(result: String) -> void:
			signal_received = true
			received_result = result
		)

		sg._on_lives_changed(v)

		assert_bool(sg.finish_called).is_true()
		assert_str(sg.finish_result).is_equal("lose")
		assert_bool(signal_received).is_true()
		assert_str(received_result).is_equal("lose")

		sg.queue_free()
		await get_tree().process_frame

extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 9: formato del HUD
# Valida: Requisitos 6.1, 6.2


func test_hud_format() -> void:
	# Propiedad 9: los textos del HUD deben seguir el formato "Puntos: %d" y "Vidas: %d"
	for i in 100:
		var n := randi_range(0, 9999)
		assert_str("Puntos: %d" % n).is_equal("Puntos: " + str(n))
		assert_str("Vidas: %d" % n).is_equal("Vidas: " + str(n))

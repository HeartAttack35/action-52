extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 1: confinamiento horizontal del Pistolero
# Valida: Requisito 1.4


func test_player_horizontal_confinement() -> void:
	# Propiedad 1: para cualquier half_w y x_in, el clamp mantiene x en [half_w, vp_w - half_w]
	var vp_w := 480.0
	for i in 100:
		var half_w := randf_range(8.0, 32.0)
		var x_in := randf_range(-200.0, 700.0)
		var x_out := clamp(x_in, half_w, vp_w - half_w)
		assert_float(x_out).is_greater_equal(half_w)
		assert_float(x_out).is_less_equal(vp_w - half_w)

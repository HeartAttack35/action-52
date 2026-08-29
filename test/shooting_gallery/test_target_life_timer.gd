extends GdUnitTestSuite
# Feature: shooting-gallery, Propiedad 5: rango del LifeTimer del Blanco
# Validates: Requisito 3.1

const TARGET_SCENE = preload("res://scenes/minigames/Shooting Gallery/target.tscn")


func test_target_life_timer_range() -> void:
	# Propiedad 5: wait_time debe estar en [1.5, 3.0] tras _ready()
	for i in 100:
		var target: Area2D = TARGET_SCENE.instantiate()
		add_child(target)  # necesario para que _ready() se ejecute
		var wait_time := target.get_node("LifeTimer").wait_time
		assert_float(wait_time).is_greater_equal(1.5)
		assert_float(wait_time).is_less_equal(3.0)
		target.queue_free()

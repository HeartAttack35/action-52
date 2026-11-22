extends GdUnitTestSuite
## Feature: fixed-platformer-controller — Property 4 (viewport clamping)
## Validates: Requirements 3.6
##
## Property: for any initial global_position.x (including values outside
## [0, viewport_width]), after _clamp_to_viewport() executes,
## global_position.x is within [0.0, get_viewport_rect().size.x].


func _make_controller() -> FixedPlatformerController:
	var ctrl := FixedPlatformerController.new()

	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	ctrl.add_child(sprite)

	var attack_area := Area2D.new()
	attack_area.name = "AttackArea"
	ctrl.add_child(attack_area)

	var attack_shape := CollisionShape2D.new()
	attack_shape.name = "AttackAreaShape"
	attack_area.add_child(attack_shape)

	var origin := Marker2D.new()
	origin.name = "AttackOrigin"
	ctrl.add_child(origin)

	return ctrl


# ── Property 4: position is clamped to [0, viewport_width] ───────────────────
## Validates: Requirements 3.6


func test_clamp_negative_x_to_zero() -> void:
	## Property 4: x < 0 is clamped to 0.0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position.x = -100.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_greater_equal(0.0)
	ctrl.queue_free()


func test_clamp_beyond_right_edge() -> void:
	## Property 4: x > viewport_width is clamped to viewport_width
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = get_viewport_rect().size.x
	ctrl.global_position.x = vw + 200.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_less_equal(vw)
	ctrl.queue_free()


func test_clamp_x_at_zero_stays_at_zero() -> void:
	## Boundary: x == 0 must remain 0 after clamping
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position.x = 0.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_equal(0.0)
	ctrl.queue_free()


func test_clamp_x_at_viewport_width_stays() -> void:
	## Boundary: x == viewport_width must remain unchanged after clamping
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = get_viewport_rect().size.x
	ctrl.global_position.x = vw
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_equal(vw)
	ctrl.queue_free()


func test_clamp_x_inside_range_unchanged() -> void:
	## Property 4: x already in [0, viewport_width] must not change
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = get_viewport_rect().size.x
	var mid: float = vw / 2.0
	ctrl.global_position.x = mid
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_equal(mid)
	ctrl.queue_free()


func test_clamp_property_randomised() -> void:
	## Property 4 (randomised sweep): for 100 random x values in a wide range,
	## after clamping, x is always within [0, viewport_width].
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = get_viewport_rect().size.x
	for _i in 100:
		ctrl.global_position.x = randf_range(-500.0, vw + 500.0)
		ctrl._clamp_to_viewport()
		assert_float(ctrl.global_position.x).is_greater_equal(0.0)
		assert_float(ctrl.global_position.x).is_less_equal(vw)

	ctrl.queue_free()

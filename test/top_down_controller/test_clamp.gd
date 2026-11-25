extends GdUnitTestSuite
## Feature: TopDownController — Property 7 (viewport clamping)
## Validates: Requirements 1.9
##
## Property 7: for any global_position and any strictly positive viewport size,
## after _clamp_to_viewport() executes, global_position.x is in [0, vp.x]
## and global_position.y is in [0, vp.y].
##
## Implementation note: get_viewport_rect().size returns a real viewport size
## when the node is part of the scene tree.  Viewport size is obtained via the
## controller node itself (ctrl.get_viewport_rect()) to avoid a GDScript
## static-analysis limitation with calling Node methods on GdUnitTestSuite self.


func _make_controller() -> TopDownController:
	var ctrl := TopDownController.new()
	return ctrl


# ── Property 7: position is clamped to [0, vp] ───────────────────────────────
## Validates: Requirements 1.9


func test_clamp_negative_x_to_zero() -> void:
	## Property 7: global_position.x < 0 is clamped to 0.0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position.x = -150.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_greater_equal(0.0)
	ctrl.queue_free()


func test_clamp_negative_y_to_zero() -> void:
	## Property 7: global_position.y < 0 is clamped to 0.0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position.y = -200.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.y).is_greater_equal(0.0)
	ctrl.queue_free()


func test_clamp_beyond_right_edge() -> void:
	## Property 7: x > viewport_width is clamped to viewport_width
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = ctrl.get_viewport_rect().size.x
	ctrl.global_position.x = vw + 300.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_less_equal(vw)
	ctrl.queue_free()


func test_clamp_beyond_bottom_edge() -> void:
	## Property 7: y > viewport_height is clamped to viewport_height
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vh: float = ctrl.get_viewport_rect().size.y
	ctrl.global_position.y = vh + 300.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.y).is_less_equal(vh)
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


func test_clamp_y_at_zero_stays_at_zero() -> void:
	## Boundary: y == 0 must remain 0 after clamping
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position.y = 0.0
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.y).is_equal(0.0)
	ctrl.queue_free()


func test_clamp_x_at_viewport_width_stays() -> void:
	## Boundary: x == viewport_width must remain unchanged after clamping
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = ctrl.get_viewport_rect().size.x
	ctrl.global_position.x = vw
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_equal(vw)
	ctrl.queue_free()


func test_clamp_y_at_viewport_height_stays() -> void:
	## Boundary: y == viewport_height must remain unchanged after clamping
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vh: float = ctrl.get_viewport_rect().size.y
	ctrl.global_position.y = vh
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.y).is_equal(vh)
	ctrl.queue_free()


func test_clamp_position_inside_bounds_unchanged() -> void:
	## Property 7: a position already inside the viewport must not change
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = ctrl.get_viewport_rect().size.x
	var vh: float = ctrl.get_viewport_rect().size.y
	var mid_x: float = vw * 0.5
	var mid_y: float = vh * 0.5
	ctrl.global_position = Vector2(mid_x, mid_y)
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_equal(mid_x)
	assert_float(ctrl.global_position.y).is_equal(mid_y)
	ctrl.queue_free()


func test_clamp_corner_negative_negative() -> void:
	## Property 7: corner (-x, -y) is clamped to (0, 0)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.global_position = Vector2(-500.0, -500.0)
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_greater_equal(0.0)
	assert_float(ctrl.global_position.y).is_greater_equal(0.0)
	ctrl.queue_free()


func test_clamp_corner_beyond_both_edges() -> void:
	## Property 7: corner (beyond_x, beyond_y) is clamped to (vw, vh)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = ctrl.get_viewport_rect().size.x
	var vh: float = ctrl.get_viewport_rect().size.y
	ctrl.global_position = Vector2(vw + 1000.0, vh + 1000.0)
	ctrl._clamp_to_viewport()
	assert_float(ctrl.global_position.x).is_less_equal(vw)
	assert_float(ctrl.global_position.y).is_less_equal(vh)
	ctrl.queue_free()


func test_clamp_property_randomised() -> void:
	## Property 7 (randomised sweep): for 100 random out-of-bounds positions,
	## after clamping both axes are within [0, viewport_size].
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	var vw: float = ctrl.get_viewport_rect().size.x
	var vh: float = ctrl.get_viewport_rect().size.y
	for _i in 100:
		ctrl.global_position = Vector2(
			randf_range(-500.0, vw + 500.0),
			randf_range(-500.0, vh + 500.0)
		)
		ctrl._clamp_to_viewport()
		assert_float(ctrl.global_position.x)\
			.override_failure_message("x out of bounds on iteration %d" % _i)\
			.is_greater_equal(0.0)
		assert_float(ctrl.global_position.x)\
			.override_failure_message("x exceeds vp.x on iteration %d" % _i)\
			.is_less_equal(vw)
		assert_float(ctrl.global_position.y)\
			.override_failure_message("y out of bounds on iteration %d" % _i)\
			.is_greater_equal(0.0)
		assert_float(ctrl.global_position.y)\
			.override_failure_message("y exceeds vp.y on iteration %d" % _i)\
			.is_less_equal(vh)

	ctrl.queue_free()

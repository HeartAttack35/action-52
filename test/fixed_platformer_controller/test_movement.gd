extends GdUnitTestSuite
## Feature: fixed-platformer-controller — Property 2 (sprite facing direction)
## Validates: Requirements 3.2, 3.3
##
## Property: for any non-zero direction d, _sprite.flip_h is false when d > 0
## and true when d < 0.
##
## Adaptation note: _handle_movement() reads Input.get_axis(), which cannot be
## driven in headless unit tests.  The flip logic is extracted into the public
## helper _apply_direction(direction: float) so tests call that directly.
## _handle_movement() is a one-liner that delegates to _apply_direction; both
## paths are therefore covered without coupling tests to the Input singleton.


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


# ── Property 2: flip_h matches movement direction ─────────────────────────────
## Validates: Requirements 3.2, 3.3


func test_flip_h_false_for_positive_direction() -> void:
	## Property 2: flip_h is false when direction > 0  (Req 3.2)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = true  # start in opposite state to prove it changes
	ctrl._apply_direction(1.0)
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_flip_h_false_for_fractional_positive_direction() -> void:
	## Property 2: flip_h is false for any d in (0, 1)  (Req 3.2)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = true
	ctrl._apply_direction(0.5)
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_flip_h_true_for_negative_direction() -> void:
	## Property 2: flip_h is true when direction < 0  (Req 3.3)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = false  # start in opposite state to prove it changes
	ctrl._apply_direction(-1.0)
	assert_bool(ctrl._sprite.flip_h).is_true()
	ctrl.queue_free()


func test_flip_h_true_for_fractional_negative_direction() -> void:
	## Property 2: flip_h is true for any d in (-1, 0)  (Req 3.3)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = false
	ctrl._apply_direction(-0.5)
	assert_bool(ctrl._sprite.flip_h).is_true()
	ctrl.queue_free()


func test_flip_h_unchanged_for_zero_direction_when_facing_right() -> void:
	## Boundary: d == 0 must not flip the sprite back unexpectedly
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = false
	ctrl._apply_direction(0.0)
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_flip_h_unchanged_for_zero_direction_when_facing_left() -> void:
	## Boundary: d == 0 must not reset the sprite to right-facing
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = true
	ctrl._apply_direction(0.0)
	assert_bool(ctrl._sprite.flip_h).is_true()
	ctrl.queue_free()


func test_flip_h_toggles_on_direction_reversal() -> void:
	## Property 2: flip_h tracks direction correctly across a sign change
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_direction(1.0)
	assert_bool(ctrl._sprite.flip_h).is_false()

	ctrl._apply_direction(-1.0)
	assert_bool(ctrl._sprite.flip_h).is_true()

	ctrl._apply_direction(1.0)
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_attack_shape_flips_with_direction() -> void:
	## AttackAreaShape.position.x must mirror to match facing direction
	var ctrl := _make_controller()
	ctrl.get_node("AttackArea/AttackAreaShape").position = Vector2(24.0, 0.0)
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_direction(-1.0)
	assert_float(ctrl._attack_shape.position.x).is_equal(-24.0)

	ctrl._apply_direction(1.0)
	assert_float(ctrl._attack_shape.position.x).is_equal(24.0)

	ctrl._apply_direction(0.0)
	assert_float(ctrl._attack_shape.position.x).is_equal(24.0)
	ctrl.queue_free()


func test_flip_h_property_randomised() -> void:
	## Property 2 (randomised sweep): for 100 random non-zero directions,
	## flip_h is false iff direction > 0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		# Generate a direction that is never exactly 0 so the guard fires
		var direction := randf_range(0.001, 1.0) * (1.0 if randf() > 0.5 else -1.0)
		ctrl._apply_direction(direction)
		if direction > 0.0:
			assert_bool(ctrl._sprite.flip_h).is_false()
		else:
			assert_bool(ctrl._sprite.flip_h).is_true()

	ctrl.queue_free()

extends GdUnitTestSuite
## Feature: top-down-controller — Properties 1–6 (_apply_input_vector)
## Validates: Requirements 1.2, 1.4, 1.5, 1.6, 1.7, 2.1, 2.2
##
## Properties covered:
##   1 — Non-zero input sets velocity to input.normalized() * speed (Req 1.2)
##   2 — facing_direction equals input.normalized() after non-zero input (Req 1.4)
##   3 — flip_h equals (input.normalized().x < 0.0) when rotate_sprite_to_direction = false (Req 1.6, 1.7)
##   4 — sprite.rotation equals input.normalized().angle() when rotate_sprite_to_direction = true (Req 1.5)
##   5 — WeaponPivot.rotation equals input.normalized().angle() after non-zero input (Req 2.1)
##   6 — WeaponPivot.rotation is unchanged after zero input following a non-zero input (Req 2.2)
##
## _apply_input_vector is a public helper extracted from _handle_movement so
## tests can call it directly without an Input mock.


# ── Helpers ───────────────────────────────────────────────────────────────────

## Build a TopDownController with the child nodes needed to exercise all branches.
## Sprite2D is used (not AnimatedSprite2D) so flip_h and rotation are both present.
func _make_controller() -> TopDownController:
	var ctrl := TopDownController.new()

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	ctrl.add_child(sprite)

	var pivot := Marker2D.new()
	pivot.name = "WeaponPivot"
	ctrl.add_child(pivot)

	var origin := Marker2D.new()
	origin.name = "AttackOrigin"
	origin.position = Vector2(20.0, 0.0)
	pivot.add_child(origin)

	return ctrl


## Eight canonical directions: cardinal + diagonal.
func _directions() -> Array[Vector2]:
	return [
		Vector2(1.0,  0.0),   # right
		Vector2(-1.0,  0.0),  # left
		Vector2(0.0,  1.0),   # down
		Vector2(0.0, -1.0),   # up
		Vector2(1.0,  1.0),   # down-right
		Vector2(-1.0,  1.0),  # down-left
		Vector2(1.0, -1.0),   # up-right
		Vector2(-1.0, -1.0),  # up-left
	]


const EPSILON: float = 0.0001


# ── Property 1: velocity = input.normalized() * speed ─────────────────────────
## Validates: Requirements 1.2


func test_velocity_set_for_right_input() -> void:
	## Property 1: rightward input → velocity = (1,0) * speed
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.speed = 120.0
	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	assert_vector(ctrl.velocity).is_equal(Vector2(120.0, 0.0))
	ctrl.queue_free()


func test_velocity_set_for_diagonal_input() -> void:
	## Property 1: diagonal input normalizes before multiplying by speed
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.speed = 100.0
	var input := Vector2(1.0, 1.0)
	ctrl._apply_input_vector(input)
	var expected := input.normalized() * 100.0
	assert_float(ctrl.velocity.x).is_equal_approx(expected.x, EPSILON)
	assert_float(ctrl.velocity.y).is_equal_approx(expected.y, EPSILON)
	ctrl.queue_free()


func test_velocity_zero_for_zero_input() -> void:
	## Req 1.3: zero input sets velocity to Vector2.ZERO
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.speed = 120.0
	ctrl._apply_input_vector(Vector2(1.0, 0.0))  # prime velocity
	ctrl._apply_input_vector(Vector2.ZERO)
	assert_vector(ctrl.velocity).is_equal(Vector2.ZERO)
	ctrl.queue_free()


func test_velocity_magnitude_equals_speed_for_all_directions() -> void:
	## Property 1 (parametric): for every canonical direction, |velocity| == speed
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.speed = 150.0
	for dir in _directions():
		ctrl._apply_input_vector(dir)
		assert_float(ctrl.velocity.length()).is_equal_approx(150.0, EPSILON)

	ctrl.queue_free()


func test_velocity_property_randomised() -> void:
	## Property 1 (randomised sweep): for 100 random non-zero inputs the
	## velocity magnitude equals speed and the direction is correct.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var speed := randf_range(10.0, 500.0)
		ctrl.speed = speed
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)  # avoid degenerate zero vector
		ctrl._apply_input_vector(input)
		var expected := input.normalized() * speed
		assert_float(ctrl.velocity.x)\
			.override_failure_message("velocity.x mismatch on iteration %d" % _i)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(ctrl.velocity.y)\
			.override_failure_message("velocity.y mismatch on iteration %d" % _i)\
			.is_equal_approx(expected.y, EPSILON)

	ctrl.queue_free()


# ── Property 2: facing_direction = input.normalized() ────────────────────────
## Validates: Requirements 1.4


func test_facing_direction_set_for_right_input() -> void:
	## Property 2: rightward input → facing_direction == (1, 0)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	assert_vector(ctrl.facing_direction).is_equal(Vector2(1.0, 0.0))
	ctrl.queue_free()


func test_facing_direction_set_for_left_input() -> void:
	## Property 2: leftward input → facing_direction == (-1, 0)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(-1.0, 0.0))
	assert_vector(ctrl.facing_direction).is_equal(Vector2(-1.0, 0.0))
	ctrl.queue_free()


func test_facing_direction_unchanged_on_zero_input() -> void:
	## Property 2: zero input must NOT overwrite the previous facing_direction
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(0.0, -1.0))  # face up
	ctrl._apply_input_vector(Vector2.ZERO)
	assert_vector(ctrl.facing_direction).is_equal(Vector2(0.0, -1.0))
	ctrl.queue_free()


func test_facing_direction_all_canonical_directions() -> void:
	## Property 2 (parametric): facing_direction matches normalized input for
	## all 8 canonical directions.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for dir in _directions():
		ctrl._apply_input_vector(dir)
		var expected := dir.normalized()
		assert_float(ctrl.facing_direction.x)\
			.override_failure_message("facing_direction.x wrong for dir %s" % dir)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(ctrl.facing_direction.y)\
			.override_failure_message("facing_direction.y wrong for dir %s" % dir)\
			.is_equal_approx(expected.y, EPSILON)

	ctrl.queue_free()


func test_facing_direction_property_randomised() -> void:
	## Property 2 (randomised sweep): for 100 random non-zero inputs
	## facing_direction == input.normalized().
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)
		ctrl._apply_input_vector(input)
		var expected := input.normalized()
		assert_float(ctrl.facing_direction.x)\
			.override_failure_message("facing_direction.x mismatch on iteration %d" % _i)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(ctrl.facing_direction.y)\
			.override_failure_message("facing_direction.y mismatch on iteration %d" % _i)\
			.is_equal_approx(expected.y, EPSILON)

	ctrl.queue_free()


# ── Property 3: flip_h = (input.normalized().x < 0) ─────────────────────────
## Validates: Requirements 1.6, 1.7


func test_flip_h_false_for_rightward_input() -> void:
	## Property 3 (Req 1.7): input with x >= 0 sets flip_h = false
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = true  # prime opposite state
	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_flip_h_true_for_leftward_input() -> void:
	## Property 3 (Req 1.6): input with x < 0 sets flip_h = true
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = false  # prime opposite state
	ctrl._apply_input_vector(Vector2(-1.0, 0.0))
	assert_bool(ctrl._sprite.flip_h).is_true()
	ctrl.queue_free()


func test_flip_h_false_for_upward_input() -> void:
	## Property 3: purely vertical input (x == 0) → flip_h = false (not negative)
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.flip_h = true
	ctrl._apply_input_vector(Vector2(0.0, -1.0))
	assert_bool(ctrl._sprite.flip_h).is_false()
	ctrl.queue_free()


func test_flip_h_all_canonical_directions() -> void:
	## Property 3 (parametric): flip_h matches (normalized.x < 0) for all 8 directions.
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	for dir in _directions():
		ctrl._apply_input_vector(dir)
		var expected_flip: bool = dir.normalized().x < 0.0
		assert_bool(ctrl._sprite.flip_h)\
			.override_failure_message(
				"flip_h wrong for dir %s (expected %s)" % [dir, expected_flip]
			)\
			.is_equal(expected_flip)

	ctrl.queue_free()


func test_flip_h_property_randomised() -> void:
	## Property 3 (randomised sweep): for 100 random non-zero inputs
	## flip_h == (input.normalized().x < 0.0).
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)
		ctrl._apply_input_vector(input)
		var expected_flip: bool = input.normalized().x < 0.0
		assert_bool(ctrl._sprite.flip_h)\
			.override_failure_message(
				"flip_h mismatch on iteration %d (input %s)" % [_i, input]
			)\
			.is_equal(expected_flip)

	ctrl.queue_free()


# ── Property 4: sprite.rotation = input.normalized().angle() ─────────────────
## Validates: Requirements 1.5


func test_sprite_rotation_right() -> void:
	## Property 4: rightward input → sprite.rotation == 0
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = true
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	assert_float(ctrl._sprite.rotation).is_equal_approx(0.0, EPSILON)
	ctrl.queue_free()


func test_sprite_rotation_left() -> void:
	## Property 4: leftward input → sprite.rotation == PI
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = true
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(-1.0, 0.0))
	assert_float(ctrl._sprite.rotation).is_equal_approx(PI, EPSILON)
	ctrl.queue_free()


func test_sprite_rotation_all_canonical_directions() -> void:
	## Property 4 (parametric): sprite.rotation == dir.angle() for all 8 directions.
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = true
	add_child(ctrl)
	await get_tree().process_frame

	for dir in _directions():
		ctrl._apply_input_vector(dir)
		var expected_angle := dir.normalized().angle()
		assert_float(ctrl._sprite.rotation)\
			.override_failure_message(
				"sprite.rotation wrong for dir %s (expected %f)" % [dir, expected_angle]
			)\
			.is_equal_approx(expected_angle, EPSILON)

	ctrl.queue_free()


func test_sprite_rotation_not_applied_when_flag_false() -> void:
	## Property 4 (guard): when rotate_sprite_to_direction = false, sprite.rotation
	## must NOT be touched (flip_h path instead).
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = false
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._sprite.rotation = 0.0
	ctrl._apply_input_vector(Vector2(0.0, -1.0))
	assert_float(ctrl._sprite.rotation).is_equal_approx(0.0, EPSILON)
	ctrl.queue_free()


func test_sprite_rotation_property_randomised() -> void:
	## Property 4 (randomised sweep): for 100 random non-zero inputs
	## sprite.rotation == input.normalized().angle() when rotate_sprite_to_direction = true.
	var ctrl := _make_controller()
	ctrl.rotate_sprite_to_direction = true
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)
		ctrl._apply_input_vector(input)
		var expected_angle := input.normalized().angle()
		assert_float(ctrl._sprite.rotation)\
			.override_failure_message(
				"sprite.rotation mismatch on iteration %d (input %s)" % [_i, input]
			)\
			.is_equal_approx(expected_angle, EPSILON)

	ctrl.queue_free()


# ── Property 5: WeaponPivot.rotation = input.normalized().angle() ────────────
## Validates: Requirements 2.1


func test_weapon_pivot_rotation_right() -> void:
	## Property 5: rightward input → WeaponPivot.rotation == 0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	assert_float(ctrl._weapon_pivot.rotation).is_equal_approx(0.0, EPSILON)
	ctrl.queue_free()


func test_weapon_pivot_rotation_up() -> void:
	## Property 5: upward input → WeaponPivot.rotation == -PI/2
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(0.0, -1.0))
	assert_float(ctrl._weapon_pivot.rotation).is_equal_approx(-PI / 2.0, EPSILON)
	ctrl.queue_free()


func test_weapon_pivot_rotation_all_canonical_directions() -> void:
	## Property 5 (parametric): WeaponPivot.rotation == dir.angle() for all 8 directions.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for dir in _directions():
		ctrl._apply_input_vector(dir)
		var expected_angle := dir.normalized().angle()
		assert_float(ctrl._weapon_pivot.rotation)\
			.override_failure_message(
				"WeaponPivot.rotation wrong for dir %s (expected %f)" % [dir, expected_angle]
			)\
			.is_equal_approx(expected_angle, EPSILON)

	ctrl.queue_free()


func test_weapon_pivot_rotation_property_randomised() -> void:
	## Property 5 (randomised sweep): for 100 random non-zero inputs
	## WeaponPivot.rotation == input.normalized().angle().
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)
		ctrl._apply_input_vector(input)
		var expected_angle := input.normalized().angle()
		assert_float(ctrl._weapon_pivot.rotation)\
			.override_failure_message(
				"WeaponPivot.rotation mismatch on iteration %d (input %s)" % [_i, input]
			)\
			.is_equal_approx(expected_angle, EPSILON)

	ctrl.queue_free()


# ── Property 6: WeaponPivot.rotation retained on zero input ──────────────────
## Validates: Requirements 2.2


func test_weapon_pivot_rotation_retained_after_zero_input_right() -> void:
	## Property 6: after facing right, zero input leaves WeaponPivot.rotation == 0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(1.0, 0.0))
	var rotation_before := ctrl._weapon_pivot.rotation
	ctrl._apply_input_vector(Vector2.ZERO)
	assert_float(ctrl._weapon_pivot.rotation).is_equal_approx(rotation_before, EPSILON)
	ctrl.queue_free()


func test_weapon_pivot_rotation_retained_after_zero_input_up_left() -> void:
	## Property 6: after facing up-left, zero input retains that angle
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._apply_input_vector(Vector2(-1.0, -1.0))
	var rotation_before := ctrl._weapon_pivot.rotation
	ctrl._apply_input_vector(Vector2.ZERO)
	assert_float(ctrl._weapon_pivot.rotation).is_equal_approx(rotation_before, EPSILON)
	ctrl.queue_free()


func test_weapon_pivot_rotation_retained_all_canonical_directions() -> void:
	## Property 6 (parametric): for every canonical direction, the pivot angle
	## is unchanged when zero input follows.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for dir in _directions():
		ctrl._apply_input_vector(dir)
		var rotation_before := ctrl._weapon_pivot.rotation
		ctrl._apply_input_vector(Vector2.ZERO)
		assert_float(ctrl._weapon_pivot.rotation)\
			.override_failure_message(
				"WeaponPivot.rotation changed on zero input after dir %s" % dir
			)\
			.is_equal_approx(rotation_before, EPSILON)

	ctrl.queue_free()


func test_weapon_pivot_rotation_retained_property_randomised() -> void:
	## Property 6 (randomised sweep): for 100 random non-zero directions d,
	## WeaponPivot.rotation after zero input equals WeaponPivot.rotation after d.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 100:
		var input := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		if input.length() < 0.001:
			input = Vector2(1.0, 0.0)
		ctrl._apply_input_vector(input)
		var rotation_before := ctrl._weapon_pivot.rotation
		ctrl._apply_input_vector(Vector2.ZERO)
		assert_float(ctrl._weapon_pivot.rotation)\
			.override_failure_message(
				"WeaponPivot.rotation changed after zero input on iteration %d (last dir %s)"
					% [_i, input]
			)\
			.is_equal_approx(rotation_before, EPSILON)

	ctrl.queue_free()

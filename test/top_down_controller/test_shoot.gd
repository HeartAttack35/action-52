extends GdUnitTestSuite
## Feature: TopDownController — Property 8 (shoot signal direction)
## Validates: Requirements 3.1
##
## Property 8: when _handle_shoot() fires shoot_requested, the emitted
## direction argument equals facing_direction.normalized() — regardless of
## the magnitude of facing_direction at the time of emission.
##
## Implementation note: Input.is_action_just_pressed("shoot") cannot be driven
## reliably via _physics_process in a headless test, so tests call _handle_shoot()
## directly after Input.action_press("shoot"), which sets the "just pressed"
## state for the next immediate query.  The signal is captured synchronously.


const EPSILON: float = 0.0001


func before() -> void:
	# Register the "shoot" action so Input.is_action_just_pressed("shoot") works.
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")


func after() -> void:
	if InputMap.has_action("shoot"):
		InputMap.erase_action("shoot")


func _make_controller() -> TopDownController:
	var ctrl := TopDownController.new()
	return ctrl


func _press_shoot() -> void:
	Input.action_press("shoot")


func _release_shoot() -> void:
	Input.action_release("shoot")


# ── Property 8: emitted direction == facing_direction.normalized() ────────────
## Validates: Requirements 3.1


func test_shoot_direction_right() -> void:
	## Property 8: facing RIGHT emits (1, 0)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.RIGHT
	var captured: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	# Signal is emitted synchronously; no await needed
	assert_int(captured.size()).is_equal(1)
	assert_vector(captured[0]).is_equal(Vector2.RIGHT.normalized())
	ctrl.queue_free()


func test_shoot_direction_left() -> void:
	## Property 8: facing LEFT emits (-1, 0)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.LEFT
	var captured: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	assert_int(captured.size()).is_equal(1)
	assert_vector(captured[0]).is_equal(Vector2.LEFT.normalized())
	ctrl.queue_free()


func test_shoot_direction_up() -> void:
	## Property 8: facing UP emits (0, -1)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.UP
	var captured: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	assert_int(captured.size()).is_equal(1)
	assert_vector(captured[0]).is_equal(Vector2.UP.normalized())
	ctrl.queue_free()


func test_shoot_direction_down() -> void:
	## Property 8: facing DOWN emits (0, 1)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.DOWN
	var captured: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	assert_int(captured.size()).is_equal(1)
	assert_vector(captured[0]).is_equal(Vector2.DOWN.normalized())
	ctrl.queue_free()


func test_shoot_direction_diagonal() -> void:
	## Property 8: a diagonal facing_direction is normalised before emission
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2(3.0, 4.0)  # non-unit magnitude
	var captured: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	assert_int(captured.size()).is_equal(1)
	var expected := Vector2(3.0, 4.0).normalized()
	assert_float(captured[0].x).is_equal_approx(expected.x, EPSILON)
	assert_float(captured[0].y).is_equal_approx(expected.y, EPSILON)
	ctrl.queue_free()


func test_shoot_not_emitted_without_press() -> void:
	## Boundary: calling _handle_shoot() without pressing "shoot" must not emit
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.RIGHT
	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2, _dir: Vector2) -> void: emit_count += 1)

	# Do NOT press anything — just call _handle_shoot directly
	ctrl._handle_shoot()

	assert_int(emit_count).is_equal(0)
	ctrl.queue_free()


func test_shoot_emits_once_per_press() -> void:
	## Property 8 (emission count): a single press emits exactly once
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.facing_direction = Vector2.RIGHT
	for _i in 5:
		var captured: Array[Vector2] = []
		var conn := func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir)
		ctrl.shoot_requested.connect(conn)

		_press_shoot()
		ctrl._handle_shoot()
		_release_shoot()

		assert_int(captured.size())\
			.override_failure_message("Expected 1 emission on iteration %d, got %d" % [_i, captured.size()])\
			.is_equal(1)
		assert_float(captured[0].x).is_equal_approx(ctrl.facing_direction.normalized().x, EPSILON)
		assert_float(captured[0].y).is_equal_approx(ctrl.facing_direction.normalized().y, EPSILON)

		ctrl.shoot_requested.disconnect(conn)

	ctrl.queue_free()


func test_shoot_direction_uses_facing_at_fire_time() -> void:
	## Property 8 (facing captured at fire time): changing facing_direction
	## before the press determines the emitted direction.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	# First shoot: facing right
	ctrl.facing_direction = Vector2.RIGHT
	var captured_a: Array[Vector2] = []
	var conn_a := func(_pos: Vector2, dir: Vector2) -> void: captured_a.append(dir)
	ctrl.shoot_requested.connect(conn_a)
	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()
	ctrl.shoot_requested.disconnect(conn_a)

	# Second shoot: facing up
	ctrl.facing_direction = Vector2.UP
	var captured_b: Array[Vector2] = []
	var conn_b := func(_pos: Vector2, dir: Vector2) -> void: captured_b.append(dir)
	ctrl.shoot_requested.connect(conn_b)
	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()
	ctrl.shoot_requested.disconnect(conn_b)

	assert_int(captured_a.size()).is_equal(1)
	assert_vector(captured_a[0]).is_equal(Vector2.RIGHT.normalized())
	assert_int(captured_b.size()).is_equal(1)
	assert_vector(captured_b[0]).is_equal(Vector2.UP.normalized())
	ctrl.queue_free()


func test_shoot_position_uses_global_position_without_attack_origin() -> void:
	## Requirement 3.2: when AttackOrigin is absent, position == global_position
	## (TopDownController.new() does not add WeaponPivot/AttackOrigin children,
	##  so _attack_origin is null and global_position is used as fallback.)
	var ctrl := _make_controller()
	ctrl.global_position = Vector2(128.0, 64.0)
	add_child(ctrl)
	await get_tree().process_frame

	var captured_pos: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2, _dir: Vector2) -> void: captured_pos.append(pos))

	_press_shoot()
	ctrl._handle_shoot()
	_release_shoot()

	assert_int(captured_pos.size()).is_equal(1)
	assert_vector(captured_pos[0]).is_equal(ctrl.global_position)
	ctrl.queue_free()


func test_shoot_direction_property_randomised() -> void:
	## Property 8 (randomised sweep): for 50 random non-zero facing_direction
	## values, the emitted direction equals facing_direction.normalized().
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 50:
		# Generate a non-zero direction with random magnitude
		var raw := Vector2(
			randf_range(-5.0, 5.0),
			randf_range(-5.0, 5.0)
		)
		# Avoid near-zero vectors to prevent degenerate normalisation
		if raw.length() < 0.1:
			raw = Vector2(1.0, 0.0)

		ctrl.facing_direction = raw
		var captured: Array[Vector2] = []
		var conn := func(_pos: Vector2, dir: Vector2) -> void: captured.append(dir)
		ctrl.shoot_requested.connect(conn)

		_press_shoot()
		ctrl._handle_shoot()
		_release_shoot()

		assert_int(captured.size())\
			.override_failure_message("shoot_requested not emitted on iteration %d" % _i)\
			.is_equal(1)
		var expected := raw.normalized()
		assert_float(captured[0].x)\
			.override_failure_message(
				"Direction.x mismatch on iteration %d: got %f expected %f" % [_i, captured[0].x, expected.x]
			)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(captured[0].y)\
			.override_failure_message(
				"Direction.y mismatch on iteration %d: got %f expected %f" % [_i, captured[0].y, expected.y]
			)\
			.is_equal_approx(expected.y, EPSILON)

		ctrl.shoot_requested.disconnect(conn)

	ctrl.queue_free()

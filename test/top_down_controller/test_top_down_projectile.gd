extends GdUnitTestSuite
## Feature: TopDownProjectile — Property 9 (projectile movement)
## Validates: Requirements 5.3
##
## Property 9: for any direction vector (including non-normalised), speed, and
## delta, after one _physics_process(delta) call the projectile's position has
## advanced by direction.normalized() * speed * delta.
##
## _physics_process is called directly so the test is deterministic and
## independent of the Godot physics tick rate.


const EPSILON: float = 0.0001


func _make_projectile() -> TopDownProjectile:
	return TopDownProjectile.new()


# ── Helper directions (cardinal + diagonal + non-unit magnitudes) ─────────────

func _directions() -> Array[Vector2]:
	return [
		Vector2(1.0,   0.0),   # right
		Vector2(-1.0,  0.0),   # left
		Vector2(0.0,   1.0),   # down
		Vector2(0.0,  -1.0),   # up
		Vector2(1.0,   1.0),   # down-right (diagonal, non-normalised)
		Vector2(-1.0,  1.0),   # down-left
		Vector2(1.0,  -1.0),   # up-right
		Vector2(-1.0, -1.0),   # up-left
		Vector2(3.0,   4.0),   # intentionally non-unit magnitude
		Vector2(0.5,   0.1),   # small non-unit
	]


# ── Property 9: canonical directions ─────────────────────────────────────────
## Validates: Requirements 5.3


func test_projectile_moves_right() -> void:
	## Property 9: direction=(1,0) advances position by speed*delta along x
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(1.0, 0.0)
	proj.speed = 400.0
	var start := proj.position
	proj._physics_process(0.016)
	var expected := start + Vector2(1.0, 0.0) * 400.0 * 0.016
	assert_float(proj.position.x).is_equal_approx(expected.x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(expected.y, EPSILON)
	proj.queue_free()


func test_projectile_moves_left() -> void:
	## Property 9: direction=(-1,0) advances position by speed*delta along -x
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(-1.0, 0.0)
	proj.speed = 300.0
	var start := proj.position
	proj._physics_process(0.02)
	var expected := start + Vector2(-1.0, 0.0) * 300.0 * 0.02
	assert_float(proj.position.x).is_equal_approx(expected.x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(expected.y, EPSILON)
	proj.queue_free()


func test_projectile_moves_up() -> void:
	## Property 9: direction=(0,-1) advances position by speed*delta along -y
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(0.0, -1.0)
	proj.speed = 500.0
	var start := proj.position
	proj._physics_process(0.016)
	var expected := start + Vector2(0.0, -1.0) * 500.0 * 0.016
	assert_float(proj.position.x).is_equal_approx(expected.x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(expected.y, EPSILON)
	proj.queue_free()


func test_projectile_moves_down() -> void:
	## Property 9: direction=(0,1) advances position by speed*delta along +y
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(0.0, 1.0)
	proj.speed = 200.0
	var start := proj.position
	proj._physics_process(0.033)
	var expected := start + Vector2(0.0, 1.0) * 200.0 * 0.033
	assert_float(proj.position.x).is_equal_approx(expected.x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(expected.y, EPSILON)
	proj.queue_free()


func test_projectile_normalises_diagonal_direction() -> void:
	## Property 9: a non-unit diagonal direction is normalised before scaling
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(3.0, 4.0)  # magnitude 5 — intentionally non-unit
	proj.speed = 400.0
	var start := proj.position
	proj._physics_process(0.016)
	var expected := start + Vector2(3.0, 4.0).normalized() * 400.0 * 0.016
	assert_float(proj.position.x).is_equal_approx(expected.x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(expected.y, EPSILON)
	proj.queue_free()


func test_projectile_all_canonical_directions() -> void:
	## Property 9 (parametric): for every test direction the displacement
	## equals direction.normalized() * speed * delta.
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	const SPEED: float = 400.0
	const DELTA: float = 0.016
	proj.speed = SPEED

	for dir in _directions():
		proj.position = Vector2.ZERO
		proj.direction = dir
		proj._physics_process(DELTA)
		var expected := dir.normalized() * SPEED * DELTA
		assert_float(proj.position.x)\
			.override_failure_message(
				"position.x wrong for dir %s (expected %f, got %f)" % [dir, expected.x, proj.position.x]
			)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(proj.position.y)\
			.override_failure_message(
				"position.y wrong for dir %s (expected %f, got %f)" % [dir, expected.y, proj.position.y]
			)\
			.is_equal_approx(expected.y, EPSILON)

	proj.queue_free()


func test_projectile_accumulates_over_multiple_frames() -> void:
	## Property 9 (multi-frame): displacement accumulates correctly over
	## several consecutive _physics_process calls.
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	proj.direction = Vector2(1.0, 0.0)
	proj.speed = 100.0
	proj.position = Vector2.ZERO

	var total_delta: float = 0.0
	for _i in 10:
		var delta := 0.016
		proj._physics_process(delta)
		total_delta += delta

	var expected_x := 100.0 * total_delta
	assert_float(proj.position.x).is_equal_approx(expected_x, EPSILON)
	assert_float(proj.position.y).is_equal_approx(0.0, EPSILON)
	proj.queue_free()


# ── Property 9: randomised sweep ─────────────────────────────────────────────
## Validates: Requirements 5.3


func test_projectile_movement_property_randomised() -> void:
	## Property 9 (randomised sweep): for 100 random (direction, speed, delta)
	## triples the position advance equals direction.normalized() * speed * delta.
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	for _i in 100:
		# Random non-zero direction with arbitrary magnitude
		var dir := Vector2(
			randf_range(-5.0, 5.0),
			randf_range(-5.0, 5.0)
		)
		if dir.length() < 0.001:
			dir = Vector2(1.0, 0.0)  # avoid degenerate zero vector

		var speed := randf_range(50.0, 800.0)
		var delta := randf_range(0.001, 0.05)  # realistic frame delta range

		proj.direction = dir
		proj.speed = speed
		proj.position = Vector2.ZERO  # reset each iteration

		proj._physics_process(delta)

		var expected := dir.normalized() * speed * delta
		assert_float(proj.position.x)\
			.override_failure_message(
				"position.x mismatch on iteration %d (dir=%s speed=%f delta=%f)" % [_i, dir, speed, delta]
			)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(proj.position.y)\
			.override_failure_message(
				"position.y mismatch on iteration %d (dir=%s speed=%f delta=%f)" % [_i, dir, speed, delta]
			)\
			.is_equal_approx(expected.y, EPSILON)

	proj.queue_free()


func test_projectile_movement_non_unit_directions_randomised() -> void:
	## Property 9 (randomised, large magnitudes): non-normalised directions
	## with magnitudes up to 100 are always normalised before scaling.
	var proj := _make_projectile()
	add_child(proj)
	await get_tree().process_frame

	const SPEED: float = 400.0
	const DELTA: float = 0.016
	proj.speed = SPEED

	for _i in 50:
		# Large-magnitude direction to stress-test normalisation
		var dir := Vector2(
			randf_range(-100.0, 100.0),
			randf_range(-100.0, 100.0)
		)
		if dir.length() < 0.1:
			dir = Vector2(50.0, 0.0)

		proj.direction = dir
		proj.position = Vector2.ZERO
		proj._physics_process(DELTA)

		var expected := dir.normalized() * SPEED * DELTA
		assert_float(proj.position.x)\
			.override_failure_message(
				"position.x wrong for large-magnitude dir %s on iteration %d" % [dir, _i]
			)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(proj.position.y)\
			.override_failure_message(
				"position.y wrong for large-magnitude dir %s on iteration %d" % [dir, _i]
			)\
			.is_equal_approx(expected.y, EPSILON)

	proj.queue_free()

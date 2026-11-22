extends GdUnitTestSuite
## Feature: fixed-platformer-controller — Property 8 (melee duration timer)
## Validates: Requirements 5.3
##
## Property 8: Melee hitbox disables after melee_duration
## For any melee_duration > 0, after _start_melee() is called,
## AttackAreaShape.disabled becomes true once total elapsed time >= melee_duration
## via _tick_melee_timer.


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


# Simulate a single "just pressed" input event for ui_select.
func _press_attack() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_select"
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)


func _release_attack() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_select"
	ev.pressed = false
	ev.strength = 0.0
	Input.parse_input_event(ev)


# ── Property 8: melee hitbox disables after melee_duration ───────────────────
## Validates: Requirements 5.3


func test_start_melee_enables_attack_shape() -> void:
	## _start_melee() must set disabled = false immediately (Req 5.2)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.use_melee = true
	ctrl.melee_duration = 0.2
	ctrl._start_melee()
	assert_bool(ctrl._attack_shape.disabled).is_false()
	ctrl.queue_free()


func test_shape_stays_enabled_before_duration_elapses() -> void:
	## Partial tick (delta < melee_duration) must NOT yet disable the shape
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.2
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.1)  # only half the duration
	assert_bool(ctrl._attack_shape.disabled).is_false()
	ctrl.queue_free()


func test_shape_disables_exactly_at_duration() -> void:
	## A single tick equal to melee_duration must disable the shape
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.2
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.2)
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()


func test_shape_disables_after_duration_exceeded() -> void:
	## A tick larger than melee_duration must also disable the shape
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.2
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.5)
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()


func test_shape_disables_across_two_ticks() -> void:
	## Cumulative ticks that sum to >= melee_duration must disable the shape
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.2
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.1)
	assert_bool(ctrl._attack_shape.disabled).is_false()  # still active after first tick
	ctrl._tick_melee_timer(0.1)
	assert_bool(ctrl._attack_shape.disabled).is_true()   # disabled after cumulative 0.2
	ctrl.queue_free()


func test_melee_duration_0_1_disables_after_full_tick() -> void:
	## Property 8 with melee_duration = 0.1
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.1
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.05)
	assert_bool(ctrl._attack_shape.disabled).is_false()
	ctrl._tick_melee_timer(0.05)
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()


func test_melee_duration_0_5_disables_after_full_elapsed() -> void:
	## Property 8 with melee_duration = 0.5
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	ctrl.melee_duration = 0.5
	ctrl._start_melee()
	ctrl._tick_melee_timer(0.3)
	assert_bool(ctrl._attack_shape.disabled).is_false()
	ctrl._tick_melee_timer(0.2)  # cumulative 0.5 — exactly at boundary
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()


func test_shape_stays_disabled_without_start_melee() -> void:
	## Ticking the timer when no attack was started must keep shape disabled
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	# _ready sets disabled = true; tick with no prior _start_melee
	ctrl._tick_melee_timer(1.0)
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()


func test_property8_randomised_sweep() -> void:
	## Property 8 (randomised): for many melee_duration values, the shape
	## disables once accumulated delta crosses the threshold.
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 50:
		# Pick a duration in (0.05, 1.0) so ticks aren't degenerate
		var duration: float = randf_range(0.05, 1.0)
		ctrl.melee_duration = duration
		ctrl._start_melee()
		assert_bool(ctrl._attack_shape.disabled).is_false()

		# Tick by half — shape must still be on
		ctrl._tick_melee_timer(duration * 0.5)
		assert_bool(ctrl._attack_shape.disabled).is_false()

		# Tick the remaining half — shape must turn off
		ctrl._tick_melee_timer(duration * 0.5)
		assert_bool(ctrl._attack_shape.disabled).is_true()

	ctrl.queue_free()


# ── Property 9: shoot_requested never emits when use_projectile is false ──────
## Validates: Requirements 6.2, 7.2 (projectile half)
##
## Property: for ANY sequence of attack inputs, when use_projectile = false,
## shoot_requested is never emitted — regardless of use_melee or attack_scene.


func test_shoot_requested_not_emitted_single_press() -> void:
	## Property 9 (single press): shoot_requested must not fire when
	## use_projectile = false, even on a valid attack input.
	var ctrl := _make_controller()
	ctrl.use_projectile = false
	ctrl.use_melee = false
	add_child(ctrl)
	await get_tree().process_frame

	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emit_count).is_equal(0)
	ctrl.queue_free()


func test_shoot_requested_not_emitted_with_melee_enabled() -> void:
	## Property 9 (use_melee = true, use_projectile = false): enabling melee
	## must not cause shoot_requested to fire.
	var ctrl := _make_controller()
	ctrl.use_projectile = false
	ctrl.use_melee = true
	add_child(ctrl)
	await get_tree().process_frame

	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emit_count).is_equal(0)
	ctrl.queue_free()


func test_shoot_requested_not_emitted_repeated_presses() -> void:
	## Property 9 (repeated presses): holds across multiple attack inputs in
	## sequence — the signal counter must stay at zero for all of them.
	var ctrl := _make_controller()
	ctrl.use_projectile = false
	ctrl.use_melee = true
	add_child(ctrl)
	await get_tree().process_frame

	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

	for _i in 10:
		_press_attack()
		ctrl._handle_attack()
		_release_attack()
		await get_tree().process_frame

	assert_int(emit_count).is_equal(0)
	ctrl.queue_free()


func test_shoot_requested_not_emitted_varied_use_melee() -> void:
	## Property 9 (parametric use_melee): the signal must never fire regardless
	## of whether melee is also enabled.
	var use_melee_cases: Array[bool] = [true, false, true, false, true]

	for use_melee_val in use_melee_cases:
		var ctrl := _make_controller()
		ctrl.use_projectile = false
		ctrl.use_melee = use_melee_val
		ctrl.attack_scene = null
		add_child(ctrl)
		await get_tree().process_frame

		var emit_count := 0
		ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

		_press_attack()
		ctrl._handle_attack()
		_release_attack()
		await get_tree().process_frame

		assert_int(emit_count)\
			.override_failure_message(
				"shoot_requested fired with use_melee=%s, use_projectile=false" % use_melee_val
			)\
			.is_equal(0)

		ctrl.queue_free()
		await get_tree().process_frame


func test_shoot_requested_not_emitted_no_input_pressed() -> void:
	## Boundary: when the attack action is not pressed at all, _handle_attack
	## returns early — shoot_requested must stay silent.
	var ctrl := _make_controller()
	ctrl.use_projectile = false
	add_child(ctrl)
	await get_tree().process_frame

	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

	# Do NOT press anything — just call _handle_attack directly.
	ctrl._handle_attack()

	assert_int(emit_count).is_equal(0)
	ctrl.queue_free()


func test_shoot_requested_not_emitted_property_randomised() -> void:
	## Property 9 (randomised sweep): for 50 random attack presses with varying
	## use_melee state, shoot_requested is never emitted when use_projectile = false.
	var ctrl := _make_controller()
	ctrl.use_projectile = false
	add_child(ctrl)
	await get_tree().process_frame

	var emit_count := 0
	ctrl.shoot_requested.connect(func(_pos: Vector2) -> void: emit_count += 1)

	for _i in 50:
		ctrl.use_melee = randf() > 0.5
		_press_attack()
		ctrl._handle_attack()
		_release_attack()
		await get_tree().process_frame

	assert_int(emit_count)\
		.override_failure_message(
			"shoot_requested emitted %d time(s) despite use_projectile = false" % emit_count
		)\
		.is_equal(0)

	ctrl.queue_free()


# ── Property 10: shoot_requested carries AttackOrigin's global position ───────
## Validates: Requirements 6.3, 7.3
##
## Property: when use_projectile = true and the attack action fires,
## shoot_requested is emitted with a Vector2 equal to
## AttackOrigin.global_position at that moment — including when attack_scene
## is null, and across varying AttackOrigin positions.


func test_shoot_requested_carries_origin_global_position_basic() -> void:
	## Property 10 (basic): emitted position equals _origin.global_position
	## when use_projectile = true and attack_scene = null.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = false
	ctrl.attack_scene = null
	add_child(ctrl)
	await get_tree().process_frame

	var emitted_positions: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2) -> void: emitted_positions.append(pos))

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emitted_positions.size()).is_equal(1)
	assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)
	ctrl.queue_free()


func test_shoot_requested_position_matches_after_moving_origin() -> void:
	## Property 10 (translated origin): when AttackOrigin is placed at a
	## non-default position, the emitted Vector2 reflects that position.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = false
	ctrl.attack_scene = null
	add_child(ctrl)
	await get_tree().process_frame

	ctrl._origin.position = Vector2(64.0, -16.0)
	await get_tree().process_frame  # let the scene tree propagate the new transform

	var emitted_positions: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2) -> void: emitted_positions.append(pos))

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emitted_positions.size()).is_equal(1)
	assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)
	ctrl.queue_free()


func test_shoot_requested_position_reflects_controller_global_position() -> void:
	## Property 10 (controller moved in world): moving the controller changes
	## AttackOrigin.global_position; the emitted value must track this.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = false
	ctrl.attack_scene = null
	ctrl.global_position = Vector2(200.0, 100.0)
	ctrl._origin.position = Vector2(32.0, 0.0)
	add_child(ctrl)
	await get_tree().process_frame

	var emitted_positions: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2) -> void: emitted_positions.append(pos))

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emitted_positions.size()).is_equal(1)
	assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)
	ctrl.queue_free()


func test_shoot_requested_position_unaffected_by_null_attack_scene() -> void:
	## Property 10 / Requirement 7.3: attack_scene = null must not suppress
	## shoot_requested or corrupt the emitted position.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = false
	ctrl.attack_scene = null  # explicit null — controller must still emit
	add_child(ctrl)
	await get_tree().process_frame

	var emitted_positions: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2) -> void: emitted_positions.append(pos))

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emitted_positions.size())\
		.override_failure_message("shoot_requested was not emitted when attack_scene = null")\
		.is_equal(1)
	assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)
	ctrl.queue_free()


func test_shoot_requested_position_with_both_modes_enabled() -> void:
	## Property 10 + Requirement 7.1: when use_melee = true AND
	## use_projectile = true, shoot_requested is still emitted exactly once
	## and carries the correct position.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = true
	ctrl.attack_scene = null
	add_child(ctrl)
	await get_tree().process_frame

	var emitted_positions: Array[Vector2] = []
	ctrl.shoot_requested.connect(func(pos: Vector2) -> void: emitted_positions.append(pos))

	_press_attack()
	ctrl._handle_attack()
	_release_attack()
	await get_tree().process_frame

	assert_int(emitted_positions.size()).is_equal(1)
	assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)
	ctrl.queue_free()


func test_shoot_requested_emits_once_per_press() -> void:
	## Property 10 (emission count): a single attack press produces exactly
	## one signal emission, never zero or more than one.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.use_melee = false
	ctrl.attack_scene = null
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 5:
		var emitted_positions: Array[Vector2] = []
		var conn := func(pos: Vector2) -> void: emitted_positions.append(pos)
		ctrl.shoot_requested.connect(conn)

		_press_attack()
		ctrl._handle_attack()
		_release_attack()
		await get_tree().process_frame

		assert_int(emitted_positions.size())\
			.override_failure_message("shoot_requested emitted %d times for press %d" % [emitted_positions.size(), _i])\
			.is_equal(1)
		assert_vector2(emitted_positions[0]).is_equal(ctrl._origin.global_position)

		# Disconnect by captured reference so the next iteration starts fresh
		ctrl.shoot_requested.disconnect(conn)

	ctrl.queue_free()


func test_shoot_requested_position_property_randomised() -> void:
	## Property 10 (randomised): for 50 random AttackOrigin local positions,
	## the emitted Vector2 always equals AttackOrigin.global_position at fire
	## time — regardless of attack_scene or use_melee state.
	var ctrl := _make_controller()
	ctrl.use_projectile = true
	ctrl.attack_scene = null
	add_child(ctrl)
	await get_tree().process_frame

	for _i in 50:
		ctrl.use_melee = randf() > 0.5
		# Randomise the controller's world position and the origin's local offset
		ctrl.global_position = Vector2(randf_range(0.0, 640.0), randf_range(0.0, 480.0))
		ctrl._origin.position = Vector2(randf_range(-100.0, 100.0), randf_range(-50.0, 50.0))
		await get_tree().process_frame  # propagate transforms

		var emitted_positions: Array[Vector2] = []
		var conn := func(pos: Vector2) -> void: emitted_positions.append(pos)
		ctrl.shoot_requested.connect(conn)

		_press_attack()
		ctrl._handle_attack()
		_release_attack()
		await get_tree().process_frame

		assert_int(emitted_positions.size())\
			.override_failure_message("shoot_requested not emitted on iteration %d" % _i)\
			.is_equal(1)
		assert_vector2(emitted_positions[0])\
			.override_failure_message(
				"Position mismatch on iteration %d: emitted %s, expected %s"
					% [_i, emitted_positions[0], ctrl._origin.global_position]
			)\
			.is_equal(ctrl._origin.global_position)

		ctrl.shoot_requested.disconnect(conn)

	ctrl.queue_free()

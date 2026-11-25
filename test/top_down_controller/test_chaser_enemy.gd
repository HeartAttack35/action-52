extends GdUnitTestSuite
## Feature: top-down-controller — Property 10 (ChaserEnemy velocity computation)
## Validates: Requirements 6.4
##
## Properties covered:
##   10 — For any distinct pair of Vector2 positions (enemy origin, player target)
##         and positive speed, velocity equals (target - origin).normalized() * speed.
##
## Strategy: build a minimal ChaserEnemy in-process (no scene file needed), inject
## a plain Node2D as the mock player via _player (public var), call
## _physics_process(0.0) to trigger one velocity update, then read back velocity.


const EPSILON: float = 0.0001


# ── Helpers ───────────────────────────────────────────────────────────────────

## Create a ChaserEnemy with a Sprite2D and a CollisionShape2D so _ready()
## does not error on missing children.  Returns the enemy already added to the
## scene tree so CharacterBody2D physics state initialises correctly.
func _make_enemy_with_player(enemy_pos: Vector2, player_pos: Vector2, spd: float) -> Array:
	var enemy := ChaserEnemy.new()
	enemy.speed = spd

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	enemy.add_child(col)

	var sprite := Sprite2D.new()
	enemy.add_child(sprite)

	var mock_player := Node2D.new()
	mock_player.global_position = player_pos

	add_child(mock_player)
	add_child(enemy)

	# Skip NodePath resolution — set _player directly after _ready() runs.
	enemy._player = mock_player
	enemy.global_position = enemy_pos

	return [enemy, mock_player]


# ── Property 10 canonical cases ──────────────────────────────────────────────
## Validates: Requirements 6.4


func test_velocity_points_right_toward_player() -> void:
	## Property 10: player directly to the right → velocity == (speed, 0)
	var pair := _make_enemy_with_player(Vector2(0.0, 0.0), Vector2(100.0, 0.0), 80.0)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	enemy._physics_process(0.0)

	assert_float(enemy.velocity.x).is_equal_approx(80.0, EPSILON)
	assert_float(enemy.velocity.y).is_equal_approx(0.0, EPSILON)

	enemy.queue_free()
	mock_player.queue_free()


func test_velocity_points_left_toward_player() -> void:
	## Property 10: player directly to the left → velocity == (-speed, 0)
	var pair := _make_enemy_with_player(Vector2(100.0, 0.0), Vector2(0.0, 0.0), 80.0)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	enemy._physics_process(0.0)

	assert_float(enemy.velocity.x).is_equal_approx(-80.0, EPSILON)
	assert_float(enemy.velocity.y).is_equal_approx(0.0, EPSILON)

	enemy.queue_free()
	mock_player.queue_free()


func test_velocity_points_up_toward_player() -> void:
	## Property 10: player directly above → velocity == (0, -speed)
	var pair := _make_enemy_with_player(Vector2(0.0, 100.0), Vector2(0.0, 0.0), 80.0)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	enemy._physics_process(0.0)

	assert_float(enemy.velocity.x).is_equal_approx(0.0, EPSILON)
	assert_float(enemy.velocity.y).is_equal_approx(-80.0, EPSILON)

	enemy.queue_free()
	mock_player.queue_free()


func test_velocity_points_diagonal_toward_player() -> void:
	## Property 10: diagonal player position → velocity is normalized * speed
	var enemy_pos := Vector2(0.0, 0.0)
	var player_pos := Vector2(100.0, 100.0)
	var spd := 80.0
	var pair := _make_enemy_with_player(enemy_pos, player_pos, spd)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	enemy._physics_process(0.0)

	var expected := (player_pos - enemy_pos).normalized() * spd
	assert_float(enemy.velocity.x).is_equal_approx(expected.x, EPSILON)
	assert_float(enemy.velocity.y).is_equal_approx(expected.y, EPSILON)

	enemy.queue_free()
	mock_player.queue_free()


func test_velocity_magnitude_equals_speed() -> void:
	## Property 10 (magnitude): regardless of direction, |velocity| == speed
	var pair := _make_enemy_with_player(Vector2(50.0, 30.0), Vector2(200.0, 150.0), 100.0)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	enemy._physics_process(0.0)

	assert_float(enemy.velocity.length()).is_equal_approx(100.0, EPSILON)

	enemy.queue_free()
	mock_player.queue_free()


func test_velocity_zero_when_no_player() -> void:
	## Error-handling: when _player is null (or freed), velocity is not updated
	var pair := _make_enemy_with_player(Vector2(0.0, 0.0), Vector2(100.0, 0.0), 80.0)
	var enemy: ChaserEnemy = pair[0]
	var mock_player: Node2D = pair[1]
	await get_tree().process_frame

	# Remove the player reference before calling process
	mock_player.queue_free()
	await get_tree().process_frame  # let queue_free take effect
	enemy._physics_process(0.0)

	# velocity should stay at whatever it was; guard means it is NOT updated
	# (the test just checks we don't crash and velocity stays zero from init)
	assert_float(enemy.velocity.length()).is_equal_approx(0.0, EPSILON)

	enemy.queue_free()


# ── Property 10 randomised sweep ─────────────────────────────────────────────
## Validates: Requirements 6.4


func test_velocity_property_randomised() -> void:
	## Property 10 (randomised sweep): for 100 random distinct position pairs
	## and positive speeds, velocity == (player_pos - enemy_pos).normalized() * speed.
	for _i in 100:
		var enemy_pos := Vector2(
			randf_range(-500.0, 500.0),
			randf_range(-500.0, 500.0)
		)
		var player_pos := Vector2(
			randf_range(-500.0, 500.0),
			randf_range(-500.0, 500.0)
		)
		# Ensure positions are distinct (avoid degenerate zero-direction vector)
		if enemy_pos.distance_to(player_pos) < 1.0:
			player_pos += Vector2(50.0, 0.0)

		var spd := randf_range(10.0, 300.0)

		var pair := _make_enemy_with_player(enemy_pos, player_pos, spd)
		var enemy: ChaserEnemy = pair[0]
		var mock_player: Node2D = pair[1]
		await get_tree().process_frame

		enemy._physics_process(0.0)

		var expected := (player_pos - enemy_pos).normalized() * spd
		assert_float(enemy.velocity.x)\
			.override_failure_message(
				"velocity.x mismatch on iteration %d (enemy=%s player=%s speed=%f)"
					% [_i, enemy_pos, player_pos, spd]
			)\
			.is_equal_approx(expected.x, EPSILON)
		assert_float(enemy.velocity.y)\
			.override_failure_message(
				"velocity.y mismatch on iteration %d (enemy=%s player=%s speed=%f)"
					% [_i, enemy_pos, player_pos, spd]
			)\
			.is_equal_approx(expected.y, EPSILON)

		enemy.queue_free()
		mock_player.queue_free()

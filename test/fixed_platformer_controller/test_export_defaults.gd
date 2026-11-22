extends GdUnitTestSuite
## Feature: fixed-platformer-controller — Property 1 (export default coverage)
## Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6
##
## Tests that every @export variable on FixedPlatformerController initialises
## to its documented default value.  The controller is built programmatically
## (no .tscn) so the test has no dependency on task 6.


# Build a minimal scene graph that satisfies all @onready paths so that
# _ready() can run without crashing on missing children.
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


func test_speed_default() -> void:
	## Property 1 (default coverage): speed initialises to 120.0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_float(ctrl.speed).is_equal(120.0)
	ctrl.queue_free()


func test_jump_velocity_default() -> void:
	## Property 1 (default coverage): jump_velocity initialises to -280.0
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_float(ctrl.jump_velocity).is_equal(-280.0)
	ctrl.queue_free()


func test_attack_scene_default() -> void:
	## Property 1 (default coverage): attack_scene initialises to null
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_object(ctrl.attack_scene).is_null()
	ctrl.queue_free()


func test_use_melee_default() -> void:
	## Property 1 (default coverage): use_melee initialises to true
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_bool(ctrl.use_melee).is_true()
	ctrl.queue_free()


func test_use_projectile_default() -> void:
	## Property 1 (default coverage): use_projectile initialises to false
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_bool(ctrl.use_projectile).is_false()
	ctrl.queue_free()


func test_melee_duration_default() -> void:
	## Property 1 (default coverage): melee_duration initialises to 0.2
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_float(ctrl.melee_duration).is_equal(0.2)
	ctrl.queue_free()


func test_attack_shape_disabled_on_ready() -> void:
	## _ready() must leave AttackAreaShape.disabled = true (Requirement 5.1 precondition)
	var ctrl := _make_controller()
	add_child(ctrl)
	await get_tree().process_frame
	assert_bool(ctrl._attack_shape.disabled).is_true()
	ctrl.queue_free()

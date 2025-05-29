extends CharacterBody2D

@export var speed := 200
@export var whip_distance := 300
@export var whip_strength := 10

@onready var whip_ray := $whipRay
@onready var whip_line := $whipLine

var is_swinging := false
var anchor_position: Vector2 = Vector2.ZERO

func _physics_process(delta):
	handle_movement(delta)

	if Input.is_action_just_pressed("swing"):
		try_fire_whip()

	if Input.is_action_pressed("swing") and is_swinging:
		apply_swing_force()
	else:
		is_swinging = false
		whip_line.clear_points()

func handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	if not is_swinging:
		velocity.y += 400 * delta  # Normal gravity
	# No gravity while swinging

	# Optional: clamp vertical speed
	if velocity.y > 600:
		velocity.y = 600

	move_and_slide()

	move_and_slide()

func try_fire_whip():
	var direction = (get_global_mouse_position() - global_position).normalized()
	whip_ray.global_position = global_position
	whip_ray.target_position = direction * whip_distance
	whip_ray.force_raycast_update()

	if whip_ray.is_colliding():
		var hit = whip_ray.get_collision_point()

		# Set anchor and enable swing
		anchor_position = hit
		is_swinging = true

		# Stop falling when we catch a target
		if velocity.y > 0:
			velocity.y = 0

func apply_swing_force():
	var to_anchor = anchor_position - global_position
	var rope_dir = to_anchor.normalized()

	# Tangential (swing) force only if anchor is above player
	if anchor_position.y < global_position.y:
		var swing_direction = Vector2(-rope_dir.y, rope_dir.x)

		# Flip direction if dot product is negative (wrong side)
		if velocity.dot(swing_direction) < 0:
			swing_direction = -swing_direction

		velocity += swing_direction * whip_strength

	# Always pull slightly toward anchor (acts as rope tension)
	var pull_force = rope_dir * 50
	velocity += pull_force * get_physics_process_delta_time()

	# Update visual rope
	whip_line.global_position = global_position
	whip_line.clear_points()
	whip_line.add_point(Vector2.ZERO)
	whip_line.add_point(anchor_position - global_position)

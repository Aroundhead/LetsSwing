extends CharacterBody2D

@export var speed := 300
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

	# Clamp vertical speed
	if velocity.y > 600:
		velocity.y = 600

	move_and_slide()

func try_fire_whip():
	var direction = (get_global_mouse_position() - global_position).normalized()
	whip_ray.global_position = global_position
	whip_ray.target_position = direction * whip_distance
	whip_ray.force_raycast_update()

	if whip_ray.is_colliding():
		var hit = whip_ray.get_collision_point()
		if global_position.distance_to(hit) <= whip_distance:
			anchor_position = hit
			is_swinging = true

			# Stop falling on connect
			if velocity.y > 0:
				velocity.y = 0

func apply_swing_force():
	var to_anchor = anchor_position - global_position
	var rope_length = to_anchor.length()
	var rope_dir = to_anchor / rope_length

	# 🔺 Movimiento hacia/desde el ancla
	if Input.is_action_pressed("ui_up"):
		# Reposicionar al jugador hacia el ancla (pero no instantáneo)
		global_position += rope_dir * 100 * get_physics_process_delta_time()
	elif Input.is_action_pressed("ui_down") and rope_length < whip_distance:
		# Moverse ligeramente alejándose del ancla (sin pasarse)
		global_position -= rope_dir * 100 * get_physics_process_delta_time()

	# Recalcular después del movimiento
	to_anchor = anchor_position - global_position
	rope_length = to_anchor.length()
	rope_dir = to_anchor / rope_length

	# Enforce max rope length
	if rope_length > whip_distance:
		global_position = anchor_position - rope_dir * whip_distance

	# Descomponer velocidad: eliminar componente radial
	var radial_velocity = rope_dir * velocity.dot(rope_dir)
	var tangential_velocity = velocity - radial_velocity

	# Aplicar gravedad manual
	velocity.y += 400 * get_physics_process_delta_time()

	# Mantener solo la parte tangencial
	velocity = tangential_velocity

	# Tensión hacia el ancla
	velocity += rope_dir * 50 * get_physics_process_delta_time()

	# Visual del látigo
	whip_line.global_position = global_position
	whip_line.clear_points()
	whip_line.add_point(Vector2.ZERO)
	whip_line.add_point(anchor_position - global_position)

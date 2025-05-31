extends CharacterBody2D

@export var speed := 300
@export var whip_distance := 300
@export var whip_strength := 10
@export var whip_travel_time := 0.15  
@export var synced_position: Vector2
@export var synced_velocity: Vector2

@onready var whip_ray := $whipRay
@onready var whip_line := $whipLine
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camera := $Camera2D

var is_swinging := false
var is_extending := false
var anchor_position: Vector2 = Vector2.ZERO
var whip_timer := 0.0
var whip_visual_point: Vector2 = Vector2.ZERO

func _ready():
	await get_tree().process_frame
	
	print("🎮 Yo soy el peer:", multiplayer.get_unique_id())
	print("👑 Autoridad de este nodo:", get_multiplayer_authority())

	var is_owner := multiplayer.get_unique_id() == get_multiplayer_authority()

	if is_owner:
		print("✅ Soy el dueño de este jugador y puedo moverlo")
		camera.enabled = true
	else:
		print("⛔ No soy el dueño, solo observaré")
		camera.enabled = false

	# 🔧 Forzar visibilidad si soy el dueño (opcional en redes complejas)
	synchronizer.set_visibility_for(1, true)

func _physics_process(delta):
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		handle_movement(delta)

		if Input.is_action_just_pressed("swing"):
			try_fire_whip()

		if is_extending:
			extend_whip(delta)
		elif is_swinging and Input.is_action_pressed("swing"):
			apply_swing_force()
		else:
			is_swinging = false
			whip_line.clear_points()

		synced_position = global_position
		synced_velocity = velocity
	else:
		global_position = synced_position
		velocity = synced_velocity

func handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	velocity.y += 400 * delta
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
			is_extending = true
			whip_timer = 0.0
			whip_visual_point = global_position

func extend_whip(delta):
	whip_timer += delta
	var t = clamp(whip_timer / whip_travel_time, 0.0, 1.0)
	whip_visual_point = global_position.lerp(anchor_position, t)

	whip_line.global_position = global_position
	whip_line.clear_points()
	whip_line.add_point(Vector2.ZERO)
	whip_line.add_point(whip_visual_point - global_position)

	if t >= 1.0:
		is_extending = false
		is_swinging = true
		if velocity.y > 0:
			velocity.y = 0

func apply_swing_force():
	var to_anchor = anchor_position - global_position
	var rope_length = to_anchor.length()
	var rope_dir = to_anchor / rope_length

	if Input.is_action_pressed("ui_up"):
		global_position += rope_dir * 100 * get_physics_process_delta_time()
	elif Input.is_action_pressed("ui_down") and rope_length < whip_distance:
		global_position -= rope_dir * 100 * get_physics_process_delta_time()

	to_anchor = anchor_position - global_position
	rope_length = to_anchor.length()
	rope_dir = to_anchor / rope_length

	if rope_length > whip_distance:
		global_position = anchor_position - rope_dir * whip_distance

	var radial_velocity = rope_dir * velocity.dot(rope_dir)
	var tangential_velocity = velocity - radial_velocity

	velocity.y += 400 * get_physics_process_delta_time()
	velocity = tangential_velocity
	velocity += rope_dir * 50 * get_physics_process_delta_time()

	whip_line.global_position = global_position
	whip_line.clear_points()
	whip_line.add_point(Vector2.ZERO)
	whip_line.add_point(anchor_position - global_position)

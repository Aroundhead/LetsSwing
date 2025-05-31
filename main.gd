extends Node

@export var player_scene: PackedScene
@onready var spawner := $MultiplayerSpawner

func _ready():
	var args = OS.get_cmdline_args()
	var is_server = args.has("--server")
	var is_client = args.has("--client")

	# 🔧 DEFINIR ANTES DE NADA
	spawner.spawn_function = func(peer_id):
		print("⚙️ Instanciando jugador con spawn_function para:", peer_id)
		var player = player_scene.instantiate()
		player.set_multiplayer_authority(peer_id)
		player.name = "player_%s" % str(peer_id)

		# 💡 Spawn en posición separada para cada peer
		var offset_x: int = (peer_id % 3) * 200
	 # pequeña variación horizontal
		player.global_position = Vector2(100 + offset_x, 100)

		return player

	if is_server:
		start_server()  # self = main.gd
	elif is_client:
		start_client()
	else:
		print("⚠️ Ejecuta el proyecto con --server o --client")

	spawner.spawned.connect(_on_multiplayer_spawner_spawned)


func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(12345, 32)
	multiplayer.multiplayer_peer = peer
	print("🟢 Servidor iniciado en puerto 12345")

	spawner.spawn_path = get_path()
	spawner.add_spawnable_scene(player_scene.resource_path)


func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost", 12345)
	multiplayer.multiplayer_peer = peer
	print("🔵 Cliente intentando conectarse al servidor...")

	await multiplayer.connected_to_server

	print("🔵 Cliente conectado, solicitando jugador...")

	if not multiplayer.is_server():
		rpc_id(1, "_request_spawn", multiplayer.get_unique_id())


@rpc("any_peer")
func _request_spawn(peer_id):
	if multiplayer.is_server():
		spawner.spawn(peer_id)
		print("👾 Servidor spawneó jugador para peer:", peer_id)

func print_tree_structure(node: Node, indent := 0):
	print("%s📦 %s" % [" ".repeat(indent), node.name])
	for child in node.get_children():
		print_tree_structure(child, indent + 2)

func _on_multiplayer_spawner_spawned(node):
	print("👾 Spawner creó un nodo:", node.name, "con autoridad:", node.get_multiplayer_authority())
	print("🧩 Árbol del nodo recién creado:")
	print_tree_structure(node)

	# 🧠 Extra: imprime también el árbol padre si quieres debug más completo
	print("🧠 Árbol desde main:")
	print_tree_structure(self)

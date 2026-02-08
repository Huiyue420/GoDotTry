extends Node2D

const PORT = 9999
const DEFAULT_SERVER_IP = "127.0.0.1"

@export var player_scene: PackedScene

# UI 節點引用 (會由 main.tscn 連結或透過 get_node 獲取)
@onready var host_btn = $CanvasLayer/MainMenu/Host
@onready var join_btn = $CanvasLayer/MainMenu/Join
@onready var address_input = $CanvasLayer/MainMenu/Address
@onready var menu_container = $CanvasLayer/MainMenu

# 遊戲容器
@onready var players_container = $PlayersContainer

func _ready():
	# 連結按鈕訊號
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	
	# 監聽網路事件
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("無法建立伺服器: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("等待玩家加入...")
	_hide_menu()
	
	# 伺服器自己也要生成一個角色 (ID = 1)
	spawn_player(1)

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	var ip = address_input.text
	if ip == "":
		ip = DEFAULT_SERVER_IP
	
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("無法連線: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	_hide_menu()

func _hide_menu():
	menu_container.visible = false

func _on_peer_connected(id):
	# 只有伺服器負責生成玩家
	if multiplayer.is_server():
		print("玩家 ", id, " 已連線，正在生成角色...")
		spawn_player(id)

func _on_peer_disconnected(id):
	# 只有伺服器負責移除玩家
	if multiplayer.is_server():
		print("玩家 ", id, " 斷線")
		if players_container.has_node(str(id)):
			players_container.get_node(str(id)).queue_free()

func _on_connected_ok():
	print("成功連線到伺服器！")
	# 客戶端不需要做什麼，因為 MultiplayerSpawner 會自動同步伺服器生成的節點

func _on_connected_fail():
	print("連線失敗")
	menu_container.visible = true
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	print("伺服器斷線")
	menu_container.visible = true
	multiplayer.multiplayer_peer = null
	# 清除場景上的所有玩家
	for child in players_container.get_children():
		child.queue_free()

func spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	# 隨機位置避免重疊
	player.position = Vector2(randf_range(100, 900), randf_range(100, 500))
	players_container.add_child(player, true) # true 代表 force readable name (對 Spawner 很重要)

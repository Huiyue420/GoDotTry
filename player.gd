extends CharacterBody2D

@export var speed = 300
@export var hp = 3
@export var bullet_scene: PackedScene

# 同步用的變數 (如果不用 MultiplayerSynchronizer 自動同步屬性，可手動 RPC，這裡假設用節點同步)

func _enter_tree():
	# 設定多人連線的權限
	# 如果節點名稱是數字 (Peer ID)，則將權限設為該 ID
	set_multiplayer_authority(name.to_int())

func _ready():
	# 如果是控制自己的角色，將攝影機設為目前
	if is_multiplayer_authority():
		$Camera2D.make_current()

func _physics_process(_delta):
	# 只有擁有權限的客戶端 (或是 Server 控制下的 NPC) 可以移動
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = input_dir * speed
		move_and_slide()
		
		# 簡單的滑鼠面向
		look_at(get_global_mouse_position())

		# 射擊處理 (左鍵)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# 限制射速的基本邏輯可以加在這裡
			rpc("request_fire")

# RPC: 請求射擊 (由客戶端發送給 Server)
@rpc("call_local", "any_peer", "reliable")
func request_fire():
	# 實際上通常由 Server 生成子彈
	if multiplayer.is_server():
		spawn_bullet()

func spawn_bullet():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.rotation = rotation
		# 子彈的擁有者設為發射者，避免打到自己
		bullet.shooter_id = name.to_int() 
		get_parent().add_child(bullet, true) # true force_readable_name for spawner

# RPC: 受傷 (通常由 Server 判斷後呼叫，或者子彈碰撞後呼叫)
@rpc("any_peer", "call_local", "reliable")
func take_damage():
	hp -= 1
	print("Player ", name, " took damage. HP: ", hp)
	if hp <= 0:
		die()

func die():
	print("Player ", name, " died.")
	queue_free()

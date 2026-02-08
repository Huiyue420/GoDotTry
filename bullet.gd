extends Area2D

@export var speed = 600
var shooter_id = 0

func _ready():
	# 5秒後自動銷毀，避免永遠存在
	await get_tree().create_timer(5.0).timeout
	if multiplayer.is_server():
		queue_free()

func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body):
	if not multiplayer.is_server():
		return
		
	# 忽略發射者自己
	if body.name.to_int() == shooter_id:
		return
		
	if body.has_method("take_damage"):
		body.rpc("take_damage")
		queue_free()
	elif body is StaticBody2D: # 撞牆
		queue_free()

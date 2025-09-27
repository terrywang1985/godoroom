extends Control

@onready var room_name_label = $VBoxContainer/TopPanel/TopContainer/RoomNameLabel
@onready var player_count_label = $VBoxContainer/TopPanel/TopContainer/PlayerCountLabel
@onready var game_area = $VBoxContainer/GameArea
@onready var players_container = $VBoxContainer/GameArea/PlayersContainer

var local_player_node: Node2D = null
var remote_players: Dictionary = {}
var player_speed: float = 200.0
var current_scene_index: int = 0
var scene_backgrounds: Array[String] = [
	"res://assets/backgrounds/room_scene1.webp",
	"res://assets/backgrounds/room_scene2.webp",
	"res://assets/backgrounds/room_scene3.webp"
]

# 玩家动画场景
var player_scene = preload("res://scenes/Player.tscn")

func _ready():
	# 初始化随机种子
	randomize()
	
	# 连接游戏状态信号
	GameStateManager.player_joined.connect(_on_player_joined)
	GameStateManager.player_left.connect(_on_player_left)
	GameStateManager.player_position_updated.connect(_on_player_position_updated)
	
	# 自动设置房间
	setup_room()

func setup_room():
	# 设置房间信息（符合简洁UI偏好）
	room_name_label.text = GameStateManager.get_current_room_name()
	player_count_label.text = "%d/4" % GameStateManager.players_in_room.size()
	
	# 随机选择背景场景
	_change_background_scene()
	
	# 创建本地玩家
	_create_local_player()

func _change_background_scene():
	# 使用真正的随机选择一个背景场景
	var old_index = current_scene_index
	current_scene_index = randi() % scene_backgrounds.size()
	print("随机选择背景: 从索引", old_index, "到", current_scene_index)
	
	var background_texture = load(scene_backgrounds[current_scene_index]) as Texture2D
	if background_texture:
		# 更新Background节点的纹理
		var background_node = get_node_or_null("Background")
		if background_node:
			background_node.texture = background_texture
			print("背景场景已更换为: ", scene_backgrounds[current_scene_index])
		else:
			print("警告：找不到Background节点")
	else:
		print("错误：无法加载背景纹理: ", scene_backgrounds[current_scene_index])

func _create_local_player():
	local_player_node = _create_player_node(GameStateManager.local_player_id, GameStateManager.local_player_name, Color.GREEN)
	local_player_node.position = Vector2(400, 300)  # 默认位置
	players_container.add_child(local_player_node)

func _create_player_node(player_id: int, player_name: String, color: Color) -> Node2D:
	# 使用新的动画玩家场景
	var player_node = player_scene.instantiate()
	player_node.name = "Player_" + str(player_id)
	
	# 先将节点添加到场景中，然后再调用setup
	# 这样确保节点已经在场景树中
	call_deferred("_setup_player_after_add", player_node, player_id, player_name, color)
	
	return player_node

func _setup_player_after_add(player_node: Node2D, player_id: int, player_name: String, color: Color):
	# 在下一帧调用setup，确保节点已经完全初始化
	if player_node and is_instance_valid(player_node):
		player_node.setup(player_id, player_name, color)

func _process(delta):
	if local_player_node and GameStateManager.is_in_room():
		_handle_local_player_input(delta)

func _handle_local_player_input(delta):
	var movement = Vector2.ZERO
	var is_moving = false
	
	if Input.is_action_pressed("move_left"):
		movement.x -= 1
		is_moving = true
	if Input.is_action_pressed("move_right"):
		movement.x += 1
		is_moving = true
	if Input.is_action_pressed("move_up"):
		movement.y -= 1
		is_moving = true
	if Input.is_action_pressed("move_down"):
		movement.y += 1
		is_moving = true
	
	# 播放适当的动画
	if is_moving and local_player_node.has_method("play_walk_animation"):
		local_player_node.play_walk_animation()
	elif not is_moving and local_player_node.has_method("play_idle_animation"):
		local_player_node.play_idle_animation()
	
	if movement.length() > 0:
		movement = movement.normalized()
		var new_position = local_player_node.position + movement * player_speed * delta
		
		# 限制在游戏区域内
		var game_area_size = game_area.size
		new_position.x = clamp(new_position.x, 30, game_area_size.x - 30)
		new_position.y = clamp(new_position.y, 30, game_area_size.y - 30)
		
		local_player_node.position = new_position
		
		# 发送位置更新到服务器
		NetworkManager.send_player_position(new_position)

func _on_player_joined(player_info: Dictionary):
	var player_id = player_info.id
	var player_name = player_info.name
	var position = player_info.position
	
	if player_id == GameStateManager.local_player_id:
		return  # 本地玩家已经创建
	
	# 创建远程玩家
	var player_node = _create_player_node(player_id, player_name, Color.BLUE)
	player_node.position = position
	remote_players[player_id] = player_node
	players_container.add_child(player_node)
	
	_update_player_count()

func _on_player_left(player_id: int):
	if player_id in remote_players:
		remote_players[player_id].queue_free()
		remote_players.erase(player_id)
		_update_player_count()

func _on_player_position_updated(player_id: int, position: Vector2):
	if player_id in remote_players:
		remote_players[player_id].position = position

func _update_player_count():
	var total_players = 1 + remote_players.size()  # 1 for local player
	player_count_label.text = "%d/4" % total_players

func _on_leave_button_pressed():
	print("离开房间")
	_cleanup_room()
	
	# 通知网络管理器和状态管理器
	if NetworkManager.has_method("leave_room"):
		NetworkManager.leave_room()
	GameStateManager.leave_room()
	
	# 返回大厅界面
	get_tree().change_scene_to_file("res://scenes/LobbyScreen.tscn")

func _cleanup_room():
	# 清理玩家节点
	if local_player_node:
		local_player_node.queue_free()
		local_player_node = null
	
	for player_node in remote_players.values():
		player_node.queue_free()
	remote_players.clear()
	
	print("房间清理完成")

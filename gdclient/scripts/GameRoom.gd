extends Control

@onready var room_name_label = $VBoxContainer/RoomInfoContainer/RoomNameLabel
@onready var player_count_label = $VBoxContainer/RoomInfoContainer/PlayerCountLabel
@onready var game_area = $VBoxContainer/GameArea
@onready var players_container = $VBoxContainer/GameArea/PlayersContainer

var local_player_node: Node2D = null
var remote_players: Dictionary = {}
var player_speed: float = 200.0

# 玩家方块场景（动态创建）
var player_scene = preload("res://scenes/Player.tscn")

func _ready():
	# 连接游戏状态信号
	GameStateManager.player_joined.connect(_on_player_joined)
	GameStateManager.player_left.connect(_on_player_left)
	GameStateManager.player_position_updated.connect(_on_player_position_updated)
	
	# 自动设置房间
	setup_room()

func setup_room():
	# 设置房间信息
	room_name_label.text = "房间: " + GameStateManager.get_current_room_name()
	player_count_label.text = "玩家数量: %d/4" % GameStateManager.players_in_room.size()
	
	# 创建本地玩家
	_create_local_player()

func _create_local_player():
	local_player_node = _create_player_node(GameStateManager.local_player_id, GameStateManager.local_player_name, Color.GREEN)
	local_player_node.position = Vector2(400, 300)  # 默认位置
	players_container.add_child(local_player_node)

func _create_player_node(player_id: int, player_name: String, color: Color) -> Node2D:
	var player_node = Node2D.new()
	player_node.name = "Player_" + str(player_id)
	
	# 创建方块
	var rect = ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.position = Vector2(-20, -20)
	rect.color = color
	player_node.add_child(rect)
	
	# 创建名字标签
	var label = Label.new()
	label.text = player_name
	label.position = Vector2(-20, -40)
	label.size = Vector2(40, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_node.add_child(label)
	
	return player_node

func _process(delta):
	if local_player_node and GameStateManager.is_in_room():
		_handle_local_player_input(delta)

func _handle_local_player_input(delta):
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		movement.x -= 1
	if Input.is_action_pressed("move_right"):
		movement.x += 1
	if Input.is_action_pressed("move_up"):
		movement.y -= 1
	if Input.is_action_pressed("move_down"):
		movement.y += 1
	
	if movement.length() > 0:
		movement = movement.normalized()
		var new_position = local_player_node.position + movement * player_speed * delta
		
		# 限制在游戏区域内
		var game_area_size = game_area.size
		new_position.x = clamp(new_position.x, 20, game_area_size.x - 20)
		new_position.y = clamp(new_position.y, 20, game_area_size.y - 20)
		
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
	player_count_label.text = "玩家数量: %d/4" % total_players

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

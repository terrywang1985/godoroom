extends Node

# 预加载生成的 protobuf 文件
const GameProto = preload("res://proto/game_proto.gd")

# 游戏状态管理器
signal player_position_updated(player_id: int, position: Vector2)
signal player_joined(player_info: Dictionary)
signal player_left(player_id: int)

# 当前状态
enum State {
	MENU,           # 主菜单
	LOBBY,          # 房间大厅
	IN_ROOM         # 房间内
}

var current_state: State = State.MENU
var current_room: Dictionary = {}  # 使用 Dictionary 替代 ProtobufMessage.Room
var players_in_room: Dictionary = {}  # key: player_id, value: player_info

# 玩家信息
var local_player_id: int = 0
var local_player_name: String = ""

func _ready():
	# 连接网络管理器的信号
	NetworkManager.auth_success.connect(_on_auth_success)
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.room_state_updated.connect(_on_room_state_updated)

func leave_room():
	"""离开当前房间"""
	current_room.clear()
	players_in_room.clear()
	set_state(State.LOBBY)
	print("已离开房间，返回大厅")

func _on_auth_success(user_info: Dictionary):
	local_player_id = user_info.uid
	local_player_name = user_info.nickname
	set_state(State.LOBBY)

func _on_room_created(room: Dictionary):
	current_room = room
	set_state(State.IN_ROOM)
	# 添加自己到房间
	add_player_to_room(local_player_id, local_player_name, Vector2(400, 300))

func _on_room_joined():
	set_state(State.IN_ROOM)

func _on_room_state_updated(room_state: Dictionary):
	current_room = room_state.get("room", {})
	players_in_room.clear()
	
	var players_array = room_state.get("players", [])
	for player_dict in players_array:
		add_player_to_room(
			player_dict.get("uid", 0), 
			player_dict.get("name", ""), 
			player_dict.get("position", Vector2.ZERO)
		)

func set_state(new_state: State):
	current_state = new_state
	print("游戏状态切换到: ", State.keys()[new_state])

func add_player_to_room(player_id: int, player_name: String, position: Vector2):
	var player_info = {
		"id": player_id,
		"name": player_name,
		"position": position
	}
	players_in_room[player_id] = player_info
	player_joined.emit(player_info)

func remove_player_from_room(player_id: int):
	if player_id in players_in_room:
		players_in_room.erase(player_id)
		player_left.emit(player_id)

func update_player_position(player_id: int, position: Vector2):
	if player_id in players_in_room:
		players_in_room[player_id]["position"] = position
		player_position_updated.emit(player_id, position)

func update_game_state(data: Dictionary):
	# 处理游戏状态更新
	var room_id = data.get("room_id", "")
	var player_id = data.get("player_id", 0)
	var position_dict = data.get("position", {})
	var position = Vector2(position_dict.get("x", 0), position_dict.get("y", 0))
	
	if room_id == current_room.id and player_id != local_player_id:
		update_player_position(player_id, position)

func get_current_room_name() -> String:
	if not current_room.is_empty():
		return current_room.get("name", "")
	return ""

func get_current_room_id() -> String:
	if not current_room.is_empty():
		return current_room.get("id", "")
	return ""

func is_in_room() -> bool:
	return current_state == State.IN_ROOM
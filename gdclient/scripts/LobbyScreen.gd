extends Control

@onready var room_list = $HBoxContainer/LeftPanel/RoomListContainer/RoomList
@onready var game_room = $HBoxContainer/RightPanel/GameRoom
@onready var waiting_label = $HBoxContainer/RightPanel/WaitingLabel
@onready var create_room_dialog = $CreateRoomDialog
@onready var room_name_input = $CreateRoomDialog/VBoxContainer/RoomNameInput

var current_rooms = []

func _ready():
	# 连接网络管理器的信号
	NetworkManager.room_list_received.connect(_on_room_list_received)
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	
	# 连接游戏状态管理器的信号
	GameStateManager.player_joined.connect(_on_player_joined)
	
	# 自动刷新房间列表
	_refresh_room_list()

func _on_refresh_button_pressed():
	_refresh_room_list()

func _refresh_room_list():
	NetworkManager.get_room_list()

func _on_room_list_received(rooms):
	current_rooms = rooms
	_update_room_list_ui()

func _update_room_list_ui():
	# 清空现有的房间列表
	for child in room_list.get_children():
		child.queue_free()
	
	# 添加房间项
	for room in current_rooms:
		var room_item = _create_room_item(room)
		room_list.add_child(room_item)

func _create_room_item(room: Dictionary) -> Control:
	var container = HBoxContainer.new()
	
	var info_label = Label.new()
	info_label.text = "%s (%d/%d)" % [room.get("name", ""), room.get("current_players", 0), room.get("max_players", 0)]
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(info_label)
	
	var join_button = Button.new()
	join_button.text = "加入"
	join_button.disabled = room.get("current_players", 0) >= room.get("max_players", 1)
	join_button.pressed.connect(_on_join_room_pressed.bind(room.get("id", "")))
	container.add_child(join_button)
	
	return container

func _on_join_room_pressed(room_id: String):
	print("尝试加入房间: ", room_id)
	NetworkManager.join_room(room_id)

func _on_create_room_button_pressed():
	create_room_dialog.popup_centered()
	room_name_input.text = ""
	room_name_input.grab_focus()

func _on_create_room_dialog_confirmed():
	var room_name = room_name_input.text.strip_edges()
	if room_name.is_empty():
		return
	
	print("创建房间: ", room_name)
	NetworkManager.create_room(room_name)

func _on_room_created(room: Dictionary):
	print("房间创建成功，进入房间: ", room.get("name", ""))
	_show_game_room()

func _on_room_joined():
	print("成功加入房间")
	_show_game_room()

func _show_game_room():
	waiting_label.visible = false
	game_room.visible = true
	game_room.setup_room()

func _on_player_joined(player_info: Dictionary):
	print("玩家加入房间: ", player_info.name)
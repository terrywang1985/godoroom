extends Control

@onready var room_list_container = $Panel/VBoxContainer/RoomScrollContainer/RoomList

var rooms_data = []

signal room_selected(room_id: String)
signal closed

func _ready():
	# 连接网络管理器的信号
	NetworkManager.room_list_received.connect(_on_room_list_received)

func show_room_list():
	visible = true
	_refresh_room_list()

func _refresh_room_list():
	NetworkManager.get_room_list()

func _on_room_list_received(rooms):
	rooms_data = rooms
	_update_room_display()

func _update_room_display():
	# 清空现有的房间列表
	for child in room_list_container.get_children():
		child.queue_free()
	
	# 如果没有房间
	if rooms_data.is_empty():
		var no_rooms_label = Label.new()
		no_rooms_label.text = "暂无房间"
		no_rooms_label.add_theme_font_size_override("font_size", 24)
		no_rooms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_list_container.add_child(no_rooms_label)
		return
	
	# 添加房间项
	for room in rooms_data:
		var room_item = _create_room_item(room)
		room_list_container.add_child(room_item)

func _create_room_item(room: Dictionary) -> Control:
	var room_panel = Panel.new()
	room_panel.custom_minimum_size = Vector2(0, 80)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	room_panel.add_child(hbox)
	
	# 房间信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var room_name_label = Label.new()
	room_name_label.text = "房间: " + room.get("name", "未知房间")
	room_name_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(room_name_label)
	
	var player_count_label = Label.new()
	var current_players = room.get("current_players", 0)
	var max_players = room.get("max_players", 4)
	player_count_label.text = "玩家: %d/%d" % [current_players, max_players]
	player_count_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(player_count_label)
	
	# 加入按钮
	var join_button = Button.new()
	join_button.text = "加入"
	join_button.custom_minimum_size = Vector2(80, 60)
	join_button.add_theme_font_size_override("font_size", 18)
	
	# 如果房间已满，禁用按钮
	if current_players >= max_players:
		join_button.disabled = true
		join_button.text = "已满"
	
	# 连接加入按钮信号
	var room_id = room.get("id", "")
	join_button.pressed.connect(_on_join_room_pressed.bind(room_id))
	
	hbox.add_child(join_button)
	
	return room_panel

func _on_join_room_pressed(room_id: String):
	print("加入房间: ", room_id)
	NetworkManager.join_room(room_id)
	# 发出房间选择信号
	room_selected.emit(room_id)

func _on_close_button_pressed():
	visible = false
	closed.emit()

func _on_refresh_button_pressed():
	_refresh_room_list()
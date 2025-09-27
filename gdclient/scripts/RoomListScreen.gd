extends Control

@onready var room_list_container = $MainContainer/RoomScrollContainer/RoomList

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
	# 立即清空现有的房间列表
	for child in room_list_container.get_children():
		child.queue_free()
	
	# 等待两帧确保完全清理完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 确认所有子节点都已清理
	while room_list_container.get_child_count() > 0:
		await get_tree().process_frame
	
	print("房间列表已清空，开始添加", rooms_data.size(), "个房间")
	
	# 如果没有房间
	if rooms_data.is_empty():
		var no_rooms_label = Label.new()
		no_rooms_label.text = "暂无房间"
		no_rooms_label.add_theme_font_size_override("font_size", 24)
		no_rooms_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		no_rooms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_list_container.add_child(no_rooms_label)
		return
	
	# 添加房间项
	for i in range(rooms_data.size()):
		var room = rooms_data[i]
		print("添加房间 ", i+1, ": ", room.get("name", "未知房间"))
		var room_item = _create_room_item(room)
		room_list_container.add_child(room_item)
		
		# 添加间距（除了最后一个房间）
		if i < rooms_data.size() - 1:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 20)
			room_list_container.add_child(spacer)
	
	print("房间列表显示完成，总共", room_list_container.get_child_count(), "个子节点")

func _create_room_item(room: Dictionary) -> Control:
	# 创建主容器
	var room_container = Control.new()
	room_container.custom_minimum_size = Vector2(0, 120)
	
	# 创建背景面板（类似room_list_one_row.png的效果）
	var room_panel = Panel.new()
	room_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_panel.offset_left = 20
	room_panel.offset_right = -20
	room_panel.offset_top = 10
	room_panel.offset_bottom = -10
	
	# 设置背景样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.5, 0.8)  # 深蓝色半透明
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.6, 0.8, 1.0)  # 亮蓝色边框
	room_panel.add_theme_stylebox_override("panel", style_box)
	
	room_container.add_child(room_panel)
	
	# 创建水平布局
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 30
	hbox.offset_right = -30
	hbox.offset_top = 20
	hbox.offset_bottom = -20
	room_panel.add_child(hbox)
	
	# 房间信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# 房间名称标签（符合简洁设计，去掉"房间:"前缀）
	var room_name_label = Label.new()
	room_name_label.text = room.get("name", "未知房间")
	room_name_label.add_theme_font_size_override("font_size", 24)
	room_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	room_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	room_name_label.add_theme_constant_override("shadow_offset_x", 2)
	room_name_label.add_theme_constant_override("shadow_offset_y", 2)
	info_vbox.add_child(room_name_label)
	
	# 玩家数量标签
	var current_players = room.get("current_players", 0)
	var max_players = room.get("max_players", 4)
	var player_count_label = Label.new()
	player_count_label.text = "%d/%d 玩家" % [current_players, max_players]
	player_count_label.add_theme_font_size_override("font_size", 18)
	player_count_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1, 1))
	info_vbox.add_child(player_count_label)
	
	# 进入房间按钮（使用样式化的按钮）
	var enter_button = Button.new()
	enter_button.text = "进入"
	enter_button.custom_minimum_size = Vector2(80, 40)
	
	# 按钮样式
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.7, 0.3, 0.9)  # 绿色背景
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.1, 0.5, 0.2, 1.0)
	
	enter_button.add_theme_stylebox_override("normal", button_style)
	enter_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	enter_button.add_theme_font_size_override("font_size", 18)
	
	# 如果房间已满，禁用按钮
	if current_players >= max_players:
		enter_button.disabled = true
		enter_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # 变灰
	
	# 连接加入按钮信号
	var room_id = room.get("id", "")
	enter_button.pressed.connect(_on_join_room_pressed.bind(room_id))
	
	hbox.add_child(enter_button)
	
	return room_container

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
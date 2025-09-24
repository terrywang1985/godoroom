extends Control

@onready var battle_bg = $BackgroundContainer/BattleBG
@onready var draw_bg = $BackgroundContainer/DrawBG
@onready var school_bg = $BackgroundContainer/SchoolBG
@onready var my_bg = $BackgroundContainer/MyBG

# 内容节点
@onready var battle_content = $ContentContainer/BattleContent
@onready var draw_content = $ContentContainer/DrawContent
@onready var school_content = $ContentContainer/SchoolContent
@onready var my_content = $ContentContainer/MyContent

var current_rooms = []
var current_tab = "battle"  # 当前选中的标签页

func _ready():
	# 连接网络管理器的信号
	NetworkManager.room_list_received.connect(_on_room_list_received)
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	
	# 连接游戏状态管理器的信号
	GameStateManager.player_joined.connect(_on_player_joined)
	
	# 默认显示对战页面
	_switch_to_tab("battle")
	print("大厅界面已加载")

func _switch_to_tab(tab_name: String):
	current_tab = tab_name
	print("切换到标签页: ", tab_name)
	
	# 隐藏所有背景和内容
	if battle_bg:
		battle_bg.visible = false
	if draw_bg:
		draw_bg.visible = false
	if school_bg:
		school_bg.visible = false
	if my_bg:
		my_bg.visible = false
	
	if battle_content:
		battle_content.visible = false
	if draw_content:
		draw_content.visible = false
	if school_content:
		school_content.visible = false
	if my_content:
		my_content.visible = false
	
	# 显示对应的背景和内容
	match tab_name:
		"battle":
			if battle_bg:
				battle_bg.visible = true
			if battle_content:
				battle_content.visible = true
		"draw":
			if draw_bg:
				draw_bg.visible = true
			if draw_content:
				draw_content.visible = true
		"school":
			if school_bg:
				school_bg.visible = true
			if school_content:
				school_content.visible = true
		"my":
			if my_bg:
				my_bg.visible = true
			if my_content:
				my_content.visible = true

# 创建房间按钮事件
func _on_create_room_button_pressed():
	# 自动生成房间名，无需用户输入
	var auto_room_name = _generate_room_name()
	print("自动创建房间: ", auto_room_name)
	NetworkManager.create_room(auto_room_name)

# 自动生成房间名
func _generate_room_name() -> String:
	# 获取当前时间用于生成唯一房间名
	var time = Time.get_unix_time_from_system()
	var room_names = [
		"决战之巅",
		"王者对决", 
		"巅峰较量",
		"荣耀战场",
		"传说竞技场",
		"无敌战神",
		"至尊对战"
	]
	# 随机选择一个酷炫的房间名
	var random_name = room_names[randi() % room_names.size()]
	return random_name + "_%d" % (int(time) % 10000)

# 房间列表按钮事件  
func _on_refresh_button_pressed():
	_refresh_room_list()

# 标签页按钮事件
func _on_battle_tab_pressed():
	_switch_to_tab("battle")

func _on_draw_tab_pressed():
	_switch_to_tab("draw")

func _on_school_tab_pressed():
	_switch_to_tab("school")

func _on_my_tab_pressed():
	_switch_to_tab("my")

# 其他按钮事件
func _on_quick_match_button_pressed():
	print("开始快速匹配")
	# TODO: 实现快速匹配功能

func _refresh_room_list():
	NetworkManager.get_room_list()

func _on_room_list_received(rooms):
	current_rooms = rooms
	print("收到房间列表: ", rooms.size(), "个房间")
	# TODO: 显示房间列表界面

func _on_room_created(room: Dictionary):
	print("房间创建成功，进入房间: ", room.get("name", ""))
	_show_game_room()

func _on_room_joined():
	print("成功加入房间")
	_show_game_room()

func _show_game_room():
	print("切换到游戏房间（可移动状态）")
	# 切换到可以移动的游戏房间场景
	get_tree().change_scene_to_file("res://scenes/GameRoom.tscn")

func _on_player_joined(player_info: Dictionary):
	print("玩家加入房间: ", player_info.name)
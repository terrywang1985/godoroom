extends Control

@onready var hand_cards_container = $HandArea/HandCardsContainer
@onready var played_cards_container = $PlayArea/PlayedCardsContainer
@onready var play_area = $PlayArea
@onready var room_info_label = $UI/TopBar/RoomInfo

var card_scene = preload("res://scenes/Card.tscn")
var cards_in_hand: Array[Control] = []
var cards_on_table: Array[Control] = []

func _ready():
	# 设置房间信息
	room_info_label.text = "卡牌游戏 - " + GameStateManager.get_current_room_name()
	
	# 创建初始手牌
	_create_initial_hand()
	
	print("卡牌游戏房间初始化完成")

func _create_initial_hand():
	# 创建5张卡牌
	for i in range(5):
		var card = card_scene.instantiate()
		
		# 随机分配卡面和边框
		var face_index = i  # 使用前5张不同的卡面
		var frame_index = randi() % 2  # 随机选择边框
		
		card.setup_card(i + 1, face_index, frame_index)
		
		# 连接信号
		card.card_played.connect(_on_card_played)
		card.card_returned_to_hand.connect(_on_card_returned_to_hand)
		
		# 添加到手牌容器
		hand_cards_container.add_child(card)
		cards_in_hand.append(card)
		
		print("创建手牌卡牌:", i + 1)
	
	# 调整手牌布局
	_arrange_hand_cards()

func _arrange_hand_cards():
	# HBoxContainer会自动排列，但我们可以调整间距
	hand_cards_container.add_theme_constant_override("separation", 10)

func is_in_play_area(global_pos: Vector2) -> bool:
	# 检查位置是否在桌面游戏区域内
	var play_area_rect = Rect2(play_area.global_position, play_area.size)
	return play_area_rect.has_point(global_pos)

func _on_card_played(card: Control):
	# 卡牌被放置到桌面
	cards_in_hand.erase(card)
	cards_on_table.append(card)
	
	# 重新排列手牌
	_arrange_hand_cards()
	
	# 将卡牌移动到桌面容器
	card.reparent(played_cards_container)
	
	# 随机放置在桌面上（可以根据需要调整位置逻辑）
	var random_pos = Vector2(
		randf_range(0, played_cards_container.size.x - card.size.x),
		randf_range(0, played_cards_container.size.y - card.size.y)
	)
	card.position = random_pos
	
	print("卡牌放置到桌面，当前手牌数量:", cards_in_hand.size())

func _on_card_returned_to_hand(card: Control):
	# 卡牌返回手牌
	if card not in cards_in_hand:
		cards_in_hand.append(card)
		cards_on_table.erase(card)
	
	print("卡牌返回手牌，当前手牌数量:", cards_in_hand.size())

func _on_back_button_pressed():
	# 返回大厅
	GameStateManager.set_state(GameStateManager.State.LOBBY)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
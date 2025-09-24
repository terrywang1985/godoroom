extends Control

@onready var card_face = $CardFace
@onready var card_frame = $CardFrame

var card_id: int = 0
var card_data: Dictionary = {}
var is_dragging: bool = false
var drag_offset: Vector2
var original_position: Vector2
var original_parent: Node
var in_hand: bool = true

# 卡牌资源路径
var card_face_paths = [
	"res://assets/cardface/r_0001.png",
	"res://assets/cardface/r_0002.png", 
	"res://assets/cardface/r_0003.png",
	"res://assets/cardface/sr_0001.png",
	"res://assets/cardface/ssr_0001.png"
]

var card_frame_paths = [
	"res://assets/carframe/card_frame.png",
	"res://assets/carframe/card_frame1.png"
]

signal card_played(card)
signal card_returned_to_hand(card)

func _ready():
	# 设置卡牌可拖拽
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_card(id: int, face_index: int = 0, frame_index: int = 0):
	card_id = id
	
	# 加载卡面
	if face_index < card_face_paths.size():
		var face_texture = load(card_face_paths[face_index])
		card_face.texture = face_texture
	
	# 加载卡牌边框
	if frame_index < card_frame_paths.size():
		var frame_texture = load(card_frame_paths[frame_index])
		card_frame.texture = frame_texture
	
	print("卡牌创建完成 ID:", id, " 卡面:", face_index, " 边框:", frame_index)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)

func _start_drag(mouse_pos: Vector2):
	if not in_hand:
		return
		
	is_dragging = true
	drag_offset = mouse_pos
	original_position = global_position
	original_parent = get_parent()
	
	# 移动到最顶层以便拖拽时显示在其他卡牌上方
	var main_scene = get_tree().current_scene
	if main_scene:
		reparent(main_scene)
		global_position = original_position
	
	# 放大卡牌
	create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	z_index = 100

func _update_drag(mouse_pos: Vector2):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _end_drag():
	if not is_dragging:
		return
		
	is_dragging = false
	
	# 检查是否在桌面区域
	var game_room = get_tree().get_first_node_in_group("game_room")
	if game_room and game_room.has_method("is_in_play_area"):
		if game_room.is_in_play_area(global_position):
			# 放置到桌面
			_play_card()
		else:
			# 返回手牌
			_return_to_hand()
	else:
		_return_to_hand()

func _play_card():
	in_hand = false
	scale = Vector2(1.0, 1.0)
	z_index = 1
	card_played.emit(self)
	print("卡牌已放置到桌面:", card_id)

func _return_to_hand():
	scale = Vector2(1.0, 1.0)
	z_index = 1
	
	# 返回原位置
	if original_parent:
		reparent(original_parent)
		position = Vector2.ZERO  # 手牌容器会自动排列
	
	# 平滑动画返回
	var tween = create_tween()
	tween.tween_property(self, "global_position", original_position, 0.2)
	
	card_returned_to_hand.emit(self)
	print("卡牌返回手牌:", card_id)

func _on_mouse_entered():
	if in_hand and not is_dragging:
		create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited():
	if in_hand and not is_dragging:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
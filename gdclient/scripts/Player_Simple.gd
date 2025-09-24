extends Node2D

var player_id: int = 0
var player_name: String = ""

# 可用的角色emoji列表
var character_emojis = ["🧙", "🧝", "🧛", "🧚", "🥷", "👨‍💻", "👩‍💻", "🤖", "👾", "🐱", "🐺", "🦊"]

func setup(id: int, name: String, color: Color):
	player_id = id
	player_name = name
	
	# 根据玩家ID选择不同的emoji角色
	var emoji_index = id % character_emojis.size()
	var emoji = character_emojis[emoji_index]
	
	# 创建角色Label
	var character_label = Label.new()
	character_label.text = emoji
	character_label.add_theme_font_size_override("font_size", 32)
	character_label.position = Vector2(-16, -24)
	add_child(character_label)
	
	# 如果想要颜色效果，可以添加ColorRect作为背景
	if color != Color.WHITE:
		var bg_rect = ColorRect.new()
		bg_rect.size = Vector2(40, 40)
		bg_rect.position = Vector2(-20, -20)
		bg_rect.color = Color(color.r, color.g, color.b, 0.3)  # 半透明背景
		add_child(bg_rect)
		move_child(character_label, -1)  # 把emoji放在最前面
	
	# 设置玩家名字
	$NameLabel.text = name
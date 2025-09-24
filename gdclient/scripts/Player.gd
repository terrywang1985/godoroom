extends Node2D

var player_id: int = 0
var player_name: String = ""

func setup(id: int, name: String, color: Color):
	player_id = id
	player_name = name
	
	# 创建圆形纹理
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center = Vector2(16, 16)
	var radius = 14
	
	# 绘制圆形
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))  # 透明
	
	# 创建纹理并应用
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	$Sprite2D.texture = texture
	
	# 设置玩家名字
	$NameLabel.text = name
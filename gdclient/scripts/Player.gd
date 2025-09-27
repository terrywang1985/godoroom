extends Node2D

var player_id: int = 0
var player_name: String = ""
var animation_speed: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel

func _ready():
	# 在_ready中确保节点引用正确
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not name_label:
		name_label = get_node_or_null("NameLabel")

func setup(id: int, name: String, color: Color):
	player_id = id
	player_name = name
	
	# 确保节点已经加入场景树
	if not is_inside_tree():
		# 等待节点加入场景树
		await tree_entered
	
	# 等待一帧确保所有子节点都已准备完成
	await get_tree().process_frame
	
	# 设置玩家名字
	if name_label:
		name_label.text = name
		name_label.modulate = color
	
	# 加载和设置动画
	_setup_animation()

func _setup_animation():
	# 确保animated_sprite存在
	if not animated_sprite:
		print("错误：AnimatedSprite2D节点不存在")
		_create_fallback_animation()
		return
	
	# 参考gdanimation中的成功实现
	var texture = load("res://assets/animations/jigger.png") as Texture2D
	if not texture:
		print("警告：无法加载jigger.png，使用备用动画")
		_create_fallback_animation()
		return
	
	print("正在设置 sprite sheet，尺寸: ", texture.get_size(), "，帧数: 3")
	
	# 参考gdanimation的实现
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("walk")  # 使用walk替代action
	
	# 计算每帧宽度（参考gdanimation）
	var frame_count = 3
	var frame_width = texture.get_width() / frame_count
	var frame_height = texture.get_height()
	
	print("每帧尺寸: ", frame_width, "x", frame_height)
	
	# 创建每一帧（idle动画）
	for i in range(frame_count):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		
		frames.add_frame("idle", atlas_texture, 0.5)  # 增加idle动画间隔
	
	# 反向添加动作帧（walk动画）
	for i in range(frame_count - 1, -1, -1):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		
		frames.add_frame("walk", atlas_texture, 0.2)  # 增加walk动画间隔
	
	# 设置到AnimatedSprite2D
	animated_sprite.sprite_frames = frames
	
	# 确保动画存在后再播放
	if frames.has_animation("idle"):
		animated_sprite.play("idle")
		print("动画设置完成")
	else:
		print("错误：idle动画不存在")
		_create_fallback_animation()

func _create_fallback_animation():
	# 创建备用动画（类似gdanimation中的占位图片）
	if not animated_sprite:
		print("错误：AnimatedSprite2D不存在，无法创建备用动画")
		return
		
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("walk")
	
	# 参考gdanimation的create_placeholder_texture方法
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.9, 1.0))  # 紫色占位，确保可见
	
	# 添加一些图案让它更明显
	for x in range(64):
		for y in range(64):
			if (x + y) % 16 < 8:
				image.set_pixel(x, y, Color(0.9, 0.6, 1.0, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# 添加帧（参考gdanimation的做法）
	for i in range(3):
		frames.add_frame("idle", texture, 0.5)
	
	for i in range(2, -1, -1):
		frames.add_frame("walk", texture, 0.2)
	
	# 设置动画
	animated_sprite.sprite_frames = frames
	
	# 确保动画存在后再播放
	if frames.has_animation("idle"):
		animated_sprite.play("idle")
		print("备用动画设置完成")
	else:
		print("错误：备用动画创建失败")

func play_walk_animation():
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.animation != "walk":
		animated_sprite.play("walk")

func play_idle_animation():
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.animation != "idle":
		animated_sprite.play("idle")
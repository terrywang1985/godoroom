extends Control

@onready var guest_login_button = $UIContainer/ButtonContainer/GuestLoginButton

func _ready():
	# 连接网络管理器的信号
	NetworkManager.http_login_success.connect(_on_http_login_success)
	NetworkManager.http_login_failed.connect(_on_http_login_failed)
	NetworkManager.connected.connect(_on_websocket_connected)
	NetworkManager.disconnected.connect(_on_disconnected)
	NetworkManager.auth_success.connect(_on_auth_success)
	NetworkManager.auth_failed.connect(_on_auth_failed)

func _on_guest_login_button_pressed():
	guest_login_button.disabled = true
	print("开始游客登录...")
	
	print("使用默认登录地址: ", NetworkManager.login_url)
	
	# 开始HTTP游客登录
	if not NetworkManager.guest_login():
		print("HTTP请求发送失败")
		guest_login_button.disabled = false

func _on_http_login_success(token: String):
	print("步骤2: HTTP登录成功，已获得Gateway地址，正在连接WebSocket...")
	print("获得session_token: ", token)

func _on_http_login_failed(error_msg: String):
	print("HTTP登录失败: " + error_msg)
	guest_login_button.disabled = false

func _on_websocket_connected():
	print("步骤3: WebSocket已连接，正在认证...")
	# WebSocket连接成功后使用session_token进行认证
	NetworkManager.websocket_auth()

func _on_disconnected():
	print("连接断开")
	guest_login_button.disabled = false

func _on_auth_success(user_info):
	print("步骤4: 认证成功！欢迎 " + user_info.nickname)
	await get_tree().create_timer(1.0).timeout
	# 主场景会自动切换到大厅界面

func _on_auth_failed(error_msg):
	print("WebSocket认证失败: " + error_msg)
	guest_login_button.disabled = false
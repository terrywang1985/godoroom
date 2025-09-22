extends Control

@onready var login_screen = $LoginScreen
@onready var lobby_screen = $LobbyScreen

func _ready():
	# 连接网络管理器的信号
	NetworkManager.auth_success.connect(_on_auth_success)
	
	# 初始显示登录界面
	show_login_screen()

func _on_auth_success(_user_info):
	show_lobby_screen()

func show_login_screen():
	login_screen.visible = true
	lobby_screen.visible = false

func show_lobby_screen():
	login_screen.visible = false
	lobby_screen.visible = true
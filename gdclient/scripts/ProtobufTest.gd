extends Node

# 测试脚本 - 验证 protobuf 消息的创建和使用
const GameProto = preload("res://proto/game_proto.gd")

func _ready():
	print("=== Protobuf 测试开始 ===")
	test_auth_request()
	test_room_creation()
	test_message_serialization()
	print("=== Protobuf 测试完成 ===")

func test_auth_request():
	print("\n1. 测试 AuthRequest 消息创建:")
	var auth_req = GameProto.AuthRequest.new()
	
	# 设置字段
	auth_req.set_device_id("test_device_123")
	auth_req.set_timestamp(Time.get_unix_time_from_system())
	auth_req.set_is_guest(true)
	auth_req.set_app_id("godoroom")
	auth_req.set_protocol_version("1.0")
	
	print("  - Device ID: ", auth_req.get_device_id())
	print("  - Is Guest: ", auth_req.get_is_guest())
	print("  - App ID: ", auth_req.get_app_id())
	print("  - Protocol Version: ", auth_req.get_protocol_version())

func test_room_creation():
	print("\n2. 测试 Room 消息创建:")
	var room = GameProto.Room.new()
	
	room.set_id("room_001")
	room.set_name("测试房间")
	room.set_max_players(4)
	room.set_current_players(1)
	
	print("  - Room ID: ", room.get_id())
	print("  - Room Name: ", room.get_name())
	print("  - Max Players: ", room.get_max_players())
	print("  - Current Players: ", room.get_current_players())

func test_message_serialization():
	print("\n3. 测试消息序列化:")
	var message = GameProto.Message.new()
	
	message.set_clientId("client_123")
	message.set_msgSerialNo(1)
	message.set_id(2)  # AUTH_REQUEST
	
	print("  - Client ID: ", message.get_clientId())
	print("  - Message Serial No: ", message.get_msgSerialNo())
	print("  - Message ID: ", message.get_id())
	
	# 尝试序列化
	var bytes = message.to_bytes()
	print("  - Serialized bytes length: ", bytes.size())
	
	# 尝试反序列化
	var new_message = GameProto.Message.new()
	var result = new_message.from_bytes(bytes)
	if result == GameProto.PB_ERR.NO_ERRORS:
		print("  - Deserialization successful!")
		print("  - Deserialized Client ID: ", new_message.get_clientId())
	else:
		print("  - Deserialization failed with error: ", result)
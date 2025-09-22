# GodoRoom - 多人在线房间游戏

这是一个基于 Godot 4.4 开发的多人在线房间游戏，使用 WebSocket + Protobuf 协议与服务器通信。

## 功能特性

### ✅ 已实现功能
- **游客登录**: 点击游客登录按钮，无需注册即可进入游戏
- **房间系统**: 
  - 查看房间列表
  - 创建新房间
  - 加入现有房间
- **多人互动**: 
  - 实时玩家移动同步
  - 玩家加入/离开房间通知
  - 房间内玩家列表显示
- **游戏控制**: 
  - WASD 控制玩家移动
  - 实时位置同步到其他玩家

### 🎮 游戏玩法
1. 启动游戏后，点击"游客登录"按钮
2. 登录成功后进入房间大厅
3. 可以选择：
   - **刷新房间列表**: 查看当前可用房间
   - **创建房间**: 输入房间名称创建新房间
   - **加入房间**: 点击房间列表中的"加入"按钮
4. 进入房间后：
   - 绿色方块代表自己
   - 蓝色方块代表其他玩家
   - 使用 WASD 键移动你的角色
   - 其他玩家能实时看到你的移动

## 技术架构

### 前端 (Godot 4.4)
- **主要场景**:
  - `Main.tscn` - 主控制场景
  - `LoginScreen.tscn` - 登录界面
  - `LobbyScreen.tscn` - 房间大厅
  - `GameRoom.tscn` - 游戏房间
  - `Player.tscn` - 玩家角色

- **核心脚本**:
  - `NetworkManager.gd` - WebSocket 网络管理 (AutoLoad)
  - `GameState.gd` - 游戏状态管理 (AutoLoad)
  - `ProtobufMessage.gd` - 简化的 Protobuf 消息处理

### 通信协议
- **连接方式**: WebSocket
- **消息格式**: JSON (简化的 Protobuf 实现)
- **支持的消息类型**:
  - 认证请求/响应 (AUTH_REQUEST/AUTH_RESPONSE)
  - 房间列表请求/响应 (GET_ROOM_LIST_REQUEST/GET_ROOM_LIST_RESPONSE)
  - 创建房间请求/响应 (CREATE_ROOM_REQUEST/CREATE_ROOM_RESPONSE)
  - 加入房间请求/响应 (JOIN_ROOM_REQUEST/JOIN_ROOM_RESPONSE)
  - 房间状态通知 (ROOM_STATE_NOTIFICATION)
  - 游戏状态通知 (GAME_STATE_NOTIFICATION)

### 服务器要求
- 基于 jigger_protobuf 项目的 Go 服务器
- WebSocket 端点: `ws://localhost:8080/ws`
- 支持游客登录和房间管理功能

## 项目结构

```
godoroom/
├── project.godot              # Godot 项目配置
├── scenes/                    # 场景文件
│   ├── Main.tscn             # 主场景
│   ├── LoginScreen.tscn      # 登录界面
│   ├── LobbyScreen.tscn      # 房间大厅
│   ├── GameRoom.tscn         # 游戏房间
│   └── Player.tscn           # 玩家角色
├── scripts/                   # 脚本文件
│   ├── Main.gd               # 主控制脚本
│   ├── LoginScreen.gd        # 登录界面逻辑
│   ├── LobbyScreen.gd        # 大厅界面逻辑
│   ├── GameRoom.gd           # 游戏房间逻辑
│   ├── Player.gd             # 玩家逻辑
│   ├── NetworkManager.gd     # 网络管理器 (单例)
│   ├── GameState.gd          # 游戏状态管理器 (单例)
│   └── ProtobufMessage.gd    # 消息处理类
└── README.md                 # 项目说明
```

## 如何运行

### 前置条件
1. **Godot 4.4** 编辑器已安装
2. **jigger_protobuf** 服务器正在运行 (端口 8080)

### 启动步骤
1. 打开 Godot 编辑器
2. 导入项目 (`project.godot`)
3. 确保服务器地址正确 (默认: `ws://localhost:8080/ws`)
4. 点击播放按钮运行游戏
5. 在登录界面点击"游客登录"
6. 开始创建或加入房间！

### 多人测试
1. 运行多个客户端实例
2. 每个客户端都进行游客登录
3. 一个客户端创建房间
4. 其他客户端加入同一房间
5. 观察实时移动同步效果

## 控制说明
- **W/A/S/D**: 玩家移动
- **鼠标**: UI 交互
- **ESC**: 可用于离开房间 (通过"离开房间"按钮)

## 开发说明

### 扩展功能建议
- [ ] 添加真正的 Protobuf 支持 (使用 godobuf)
- [ ] 实现房间密码保护
- [ ] 添加聊天功能
- [ ] 实现游戏内容 (如简单小游戏)
- [ ] 添加玩家头像系统
- [ ] 实现断线重连功能

### 已知限制
- 当前使用简化的 JSON 消息格式，非真正的 Protobuf
- 没有实现错误处理和重试机制
- 玩家移动没有插值平滑处理
- 房间人数限制为硬编码的 4 人

这个项目展示了 Godot 4.4 中多人游戏开发的基础架构，包括网络通信、状态管理、UI 系统等核心概念。
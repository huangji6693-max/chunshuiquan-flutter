# 春水圈实时聊天架构草图

## 目标

把当前 Flutter 端从“轮询为主”逐步推进到：

- 历史消息 HTTP 拉取
- 实时消息 Centrifugo 订阅
- 断线恢复
- 增量同步
- 轮询仅作为兜底

## 组件

### Flutter App
- `flutter_chat_ui`
- `messages_provider.dart`
- `realtime_chat_service.dart`

### Spring Boot
- Auth / Match / Message / Conversation 业务服务
- Message persistence
- Centrifugo token issuing
- Publish API 封装

### Centrifugo
- WebSocket / SSE 实时传输层
- Channel subscribe / publish
- Presence / history / recovery

### Redis
- Centrifugo broker / history hot cache

### Kafka
- 业务异步消息总线

### TiDB
- 会话与历史消息持久化

## 核心流程

### 进入聊天页
1. Flutter 拉取历史消息
2. Flutter 建立实时订阅
3. UI 显示：
   - `实时连接建立中`
   - `实时连接中`
   - `轮询兜底中`

### 发送消息
1. Flutter -> Spring Boot HTTP
2. Spring Boot 校验 / 落库
3. Spring Boot -> Centrifugo publish
4. Centrifugo -> Flutter subscribers

### 收到消息
1. Centrifugo 推送 publication
2. Flutter 解析 publication / payload
3. 插入消息流
4. 去重

### 短断线恢复
1. Flutter reconnect
2. Centrifugo recovery
3. 如 recovery 不完整，HTTP 补拉历史

## Channel 命名

```text
conversation:{matchId}
```

## 推荐后端契约

### 历史消息 HTTP
```http
GET /api/matches/{matchId}/messages
```

### 发送消息 HTTP
```http
POST /api/matches/{matchId}/messages
```

### 获取 realtime token
```http
GET /api/realtime/token
```

### 可选：获取 subscription token
```http
GET /api/realtime/subscription-token?channel=conversation:{matchId}
```

### publish 目标
```text
conversation:{matchId}
```

## 当前前端状态

已完成：
- WebSocket 实时抽象接入
- 自动 fallback 轮询
- 同步模式可见化
- 连接状态可见化
- channel 概念抽象

待继续：
- 正式 Centrifugo 协议适配
- reconnect/recovery 更细粒度状态
- subscription token 接入
- 历史补偿策略
- publication envelope 解析适配

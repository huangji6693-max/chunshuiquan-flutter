# 春水圈实时聊天最小验证说明

当前 Flutter 端已接入**实时消息抽象层**：

- 优先尝试实时订阅
- 若实时层不可用，则自动降级为轮询
- 当前前端结构已开始向 Centrifugo 接入模型靠拢

## 当前前端默认实时地址

通过 `dart-define` 可覆盖：

- `REALTIME_BASE_URL`

默认值：

```text
wss://chunshuiquan-backend-production.up.railway.app/ws
```

## 当前频道约定

Flutter 端当前以会话频道为核心概念：

```text
conversation:{matchId}
```

例如：

```text
conversation:123
```

## 当前最小接入模型

现阶段前端抽象允许两种后端接法：

### 临时通用 WebSocket 接法

当前最小可跑通的路径仍可兼容：

```text
{REALTIME_BASE_URL}/matches/{matchId}?token={accessToken}
```

例如：

```text
wss://your-domain/ws/matches/123?token=xxx
```

### 正式 Centrifugo 接入方向

后续推荐演进为：

1. Spring Boot 提供 realtime token
2. Flutter 建立到 Centrifugo 的正式连接
3. Flutter 订阅 `conversation:{matchId}`
4. Spring Boot 在消息落库后 publish 到对应 channel

## 后端要满足的最小消息载荷

不管底层是临时 ws 还是正式 Centrifugo，最终前端都需要能解析成：

```json
{
  "id": "msg_001",
  "content": "你好",
  "senderId": "user_001",
  "createdAt": "2026-03-30T08:00:00Z",
  "isRead": false
}
```

## 最小验证步骤

1. 用户 A、B 已关联到同一个 matchId
2. Flutter 端进入 `/chat/{matchId}`
3. Flutter 端建立实时订阅
4. 后端在有新消息时向对应会话 channel 推送消息
5. Flutter 端无需等待轮询，应直接把消息插入当前列表顶部

## 验证通过标准

聊天页顶部当前会直接显示同步模式：
- `实时连接建立中`
- `实时连接中`
- `轮询兜底中`

满足以下任意一种即可判定实时链路已生效：

- A 发送消息给 B，B 的聊天页 1 秒内直接出现新消息
- 不切页面、不手动刷新，消息自动出现在当前会话中
- 顶部状态显示为 `实时连接中`
- 网络恢复后，重新进入前台仍能继续收到增量消息

## 当前实现说明

- 已保留轮询兜底
- 实时链路优先级高于轮询
- 后续若切换到 Centrifugo，只需替换实时接入适配层，不必推倒聊天 UI

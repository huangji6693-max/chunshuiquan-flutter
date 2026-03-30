# 春水圈实时聊天最小验证说明

当前 Flutter 端已接入**实时消息抽象层**：

- 优先尝试 WebSocket 实时订阅
- 若实时层不可用，则自动降级为轮询

## 当前前端默认实时地址

通过 `dart-define` 可覆盖：

- `REALTIME_BASE_URL`

默认值：

```text
wss://chunshuiquan-backend-production.up.railway.app/ws
```

## 当前订阅路径约定

Flutter 端当前会尝试连接：

```text
{REALTIME_BASE_URL}/matches/{matchId}?token={accessToken}
```

也就是例如：

```text
wss://your-domain/ws/matches/123?token=xxx
```

## 后端要满足的最小实时协议

WebSocket 推送的每条消息，应能被 Flutter 端按 JSON 解析成：

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

1. 用户 A、B 已经互相关联到同一个 matchId
2. Flutter 端进入 `/chat/{matchId}`
3. Flutter 端建立 WebSocket 订阅
4. 后端在有新消息时向对应 match channel 推送 JSON 消息
5. Flutter 端无需等待 5 秒轮询，应直接把消息插入列表顶部

## 验证通过标准

聊天页顶部当前会直接显示同步模式：
- `实时连接中`
- `轮询兜底中`

满足以下任意一种即可判定实时链路已生效：

- A 发送消息给 B，B 的聊天页 1 秒内直接出现新消息
- 不切页面、不手动刷新，消息自动出现在当前会话中
- 网络恢复后，重新进入前台能继续收到增量消息

## 当前实现说明

- 已保留轮询兜底
- 实时链路优先级高于轮询
- 后续若切换到 Centrifugo，只需把这个订阅抽象层替换到正式协议，不必推倒聊天 UI

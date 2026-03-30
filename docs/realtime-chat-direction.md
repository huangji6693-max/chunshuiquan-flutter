# 春水圈实时聊天接入方向

目标：实现**真正的实时聊天**，并严格遵守规则：

- 优先 GitHub 顶级开源工具
- 优先直接接入或二创
- 禁止从 0 造车

## 当前前端基础

春水圈 Flutter 端已经在使用：
- `flyerhq/flutter_chat_ui`

这意味着：
- **聊天 UI 层不用重写**
- 重点应该放在：
  - 实时消息传输层
  - 会话同步
  - 已读/重连/历史恢复

## 候选方案判断

### 方案 A：继续自己用 Spring Boot + WebSocket + Redis + Kafka 全量搭

优点：
- 自主可控
- 与现有 Java 技术栈天然一致

缺点：
- 这其实还是在造大量轮子
- 连接管理、重连恢复、订阅模型、在线状态、消息恢复、横向扩容都要自己兜
- 容易掉进“看起来不复杂，实际上全是坑”的深坑

结论：
- **不推荐作为第一选择**
- 除非只是做 very thin 的业务层，底层实时能力仍借成熟项目

---

### 方案 B：Centrifugo 作为实时消息层（推荐） ✅

GitHub:
- https://github.com/centrifugal/centrifugo

为什么它适合春水圈：
- 开源、成熟、专门做实时消息分发
- 支持 WebSocket / SSE / HTTP-streaming / GRPC
- 天然适合聊天、在线状态、实时通知
- 可与任何后端语言配合，**非常适合 Java Spring Boot 业务后端 + 独立实时层**
- 支持 Redis 扩展
- 支持 Kafka / PostgreSQL consumer/outbox 方向
- 自带很多“自己造车最容易翻车”的能力：
  - 连接管理
  - 订阅
  - 恢复
  - presence
  - history
  - reconnect

春水圈接法建议：
1. Flutter 端继续使用 `flutter_chat_ui` 负责展示
2. Spring Boot 负责：
   - 鉴权
   - 会话/消息入库
   - 业务规则
3. Centrifugo 负责：
   - 实时消息推送
   - 频道订阅
   - 在线连接层
4. Redis 作为实时层扩展/缓存支撑
5. Kafka 作为异步事件总线

这是最符合“从 1 到 2”的路线。

---

### 方案 C：GetStream Flutter Chat SDK（不推荐作为春水圈主线）

GitHub:
- https://github.com/GetStream/stream-chat-flutter

优点：
- 非常成熟
- SDK 完整
- 真正可用的实时聊天能力很强

缺点：
- 更偏 SaaS 平台接入
- 不适合你这套“Java / Spring Cloud / Redis / Kafka / TiDB / Nacos / S3”的自控后端路线
- 会把核心聊天能力绑到第三方服务

结论：
- 可以作为参考样板
- **不建议作为春水圈主线方案**

---

### 方案 D：Chatwoot

GitHub:
- https://github.com/chatwoot/chatwoot

优点：
- 非常成熟
- 开源客服聊天平台能力强

缺点：
- 更适合客服/工单/客服工作台
- 不适合直接做 dating app 的用户对用户私聊主链路

结论：
- 不适合作为春水圈主聊天主链路
- 未来如果做客服后台，可以参考或接入

## 最终建议

春水圈实时聊天优先采用：

### **Flutter Chat UI + Spring Boot 业务层 + Centrifugo 实时层 + Redis + Kafka**

也就是：
- UI：`flyerhq/flutter_chat_ui`
- 实时传输：`centrifugal/centrifugo`
- 业务后端：Java / Spring Boot / Spring Cloud
- 缓存与扩展：Redis
- 异步事件：Kafka
- 存储：TiDB

## 后续推进原则

1. 不重写聊天 UI
2. 不自己从零搭整套实时连接层
3. 优先把 Centrifugo 作为实时层候选接入方向
4. Spring Boot 只保留业务控制权，不亲自承担所有实时传输细节

## 下一步动作建议

1. 为春水圈后端单独整理一份 realtime architecture 草图
2. 设计：
   - conversation channel 命名规则
   - 鉴权 token 下发方式
   - message publish 流程
   - 历史消息拉取 + 实时增量推送协同
3. Flutter 端把当前轮询消息模型，逐步替换为：
   - 首次拉历史
   - 建立实时订阅
   - 增量插入消息
   - 断线重连恢复

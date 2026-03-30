# 春水圈实时聊天接入方向

目标：实现**真正的实时聊天**，并严格遵守规则：

- 优先 GitHub 顶级开源工具
- 优先直接接入或二创
- 禁止从 0 造车

## 当前结论

春水圈实时聊天主线确定为：

### **Flutter Chat UI + Spring Boot 业务层 + Centrifugo 实时层 + Redis + Kafka**

即：
- UI：`flyerhq/flutter_chat_ui`
- 实时层：`centrifugal/centrifugo`
- 业务后端：Java / Spring Boot / Spring Cloud
- 缓存：Redis
- 事件总线：Kafka
- 数据库存储：TiDB

这是最符合“从 1 到 2、不从 0 造车”的路线。

---

## 为什么不用纯手搓 WebSocket

自己用 Spring Boot + WebSocket + Redis + Kafka 从零搭整套实时聊天，会反复踩这些坑：

- 长连接管理
- 连接状态恢复
- 频道订阅
- 在线状态 presence
- 历史恢复
- reconnect/backoff
- 横向扩容
- reconnect storm 时的消息恢复

这些都不是“写个 websocket endpoint”就结束的。

Centrifugo 的价值就在于：
- 它把实时传输层单独做成熟了
- 后端继续专注业务规则、鉴权、落库、发布事件

---

## GitHub 直连确认到的关键点

### Centrifugo
GitHub:
- https://github.com/centrifugal/centrifugo

从官方文档/仓库可确认：
- 是独立实时消息服务器
- 适合 chat / live comments / collaborative tools
- 支持 WebSocket / SSE / HTTP-streaming / GRPC / WebTransport
- 支持 Redis 扩展
- 支持 Kafka / PostgreSQL consumer / outbox 方向
- 提供 history / recovery / presence / reconnect 能力

### Centrifuge Java
GitHub:
- https://github.com/centrifugal/centrifuge-java

可确认：
- Java / Android 客户端存在
- 说明围绕 Centrifugo 的客户端生态是成熟可用的

---

## Spring Boot + Centrifugo 的推荐职责划分

### Spring Boot 负责
- 用户鉴权
- 消息合法性校验
- 写入 TiDB
- 会话权限判断
- 生成实时连接 token / 订阅 token
- 调用 Centrifugo server API 发布消息

### Centrifugo 负责
- 长连接维护
- 频道订阅
- 实时消息广播
- reconnect / recovery
- presence / history 热缓存

### Redis 负责
- 实时层扩展 / broker / history 支撑

### Kafka 负责
- 业务异步事件总线
- 消息投递后的事件扩散
- 通知、未读数、风控、审计等异步链路

---

## 推荐消息流

### 发送消息
1. Flutter 发 HTTP 请求给 Spring Boot：发送消息
2. Spring Boot 校验身份、会话关系、消息内容
3. Spring Boot 写入 TiDB
4. Spring Boot 向 Centrifugo publish 到对应 channel
5. Centrifugo 将消息实时推送给在线订阅者
6. Flutter 收到推送，直接插入消息列表

### 拉历史消息
1. Flutter 进入聊天页
2. 先走 HTTP 拉历史消息
3. 再建立实时订阅
4. 后续只接收增量推送
5. 若短断线，则优先用 Centrifugo recovery 恢复
6. 若 recovery 不完整，再回源 Spring Boot 拉历史补齐

---

## Channel 设计建议

### 会话 channel
推荐：
```text
conversation:{matchId}
```

例如：
```text
conversation:match_123456
```

不要把太多业务字段塞进 channel 名。
channel 的核心目的是：
- 稳定
- 可订阅
- 易鉴权

---

## Token 策略建议

### 连接 token
- 用户登录后，由 Spring Boot 下发 Centrifugo connection token
- token 中至少包含用户 id / 过期时间 / 签名

### 订阅权限
- 由 Spring Boot 控制用户是否有权订阅某个 `conversation:{matchId}`
- 避免客户端自行决定可订阅哪些频道

---

## Flutter 端推进策略

当前 Flutter 端已经完成：
- 聊天 UI
- 实时消息抽象层
- 实时/轮询模式可见化
- 实时失败自动降级到轮询

下一步不是重写 UI，而是：
1. 把当前 `realtime_chat_service.dart` 从“通用 ws 协议”升级为“面向 Centrifugo 的接入适配层”
2. 增加：
   - connect state
   - reconnect state
   - subscription state
   - recovery 后补消息逻辑
3. 最终让 Flutter 端只感知：
   - 历史消息来源
   - 实时事件流
   - 同步状态

---

## 不推荐主线方案

### Stream Chat Flutter
- 强，但更偏 SaaS
- 不适合春水圈当前自控后端方向

### Chatwoot
- 更适合客服系统
- 不适合 dating app 用户私聊主链路

### 自研全套实时传输层
- 禁止作为主线
- 违反“禁止从 0 造车”规则

---

## 当前执行原则

1. 不重写聊天 UI
2. 不自己从零搭整套实时连接层
3. 优先围绕 Centrifugo 进行适配
4. Spring Boot 保持业务控制权
5. 前端只做接入和呈现，不造基础设施轮子

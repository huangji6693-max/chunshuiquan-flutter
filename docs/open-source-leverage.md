# 春水圈开源借力执行规则

目标：**禁止从 0 造车**。优先直接接入 GitHub 上成熟、顶级、活跃的开源能力；其次做二创和裁剪；最后才考虑自研。

## 硬规则

1. **先搜 GitHub，再写代码**
   - 每个新模块先找成熟开源方案
   - 满足 60%~80% 需求即可优先接入 / 二创
   - 不允许因为“自己也能写”就从零重写通用能力

2. **优先级顺序**
   1. 直接接入成熟开源项目 / SDK
   2. 基于成熟开源项目二创
   3. 仅在业务强定制部分自研

3. **禁止自研的高重复轮子**
   - 聊天 UI
   - 消息输入区 / 气泡 / 会话列表
   - 上传组件与媒体预览
   - 推送消息基础链路
   - 配置中心 / 注册中心 / 调度中心
   - 通用微服务脚手架
   - 通用后台管理基础设施

## 当前优先借力方向

### Flutter / 客户端

#### 1. Flyer Chat
- GitHub: `flyerhq/flutter_chat_ui`
- 用途：聊天 UI 基础设施
- 当前状态：已接入
- 策略：继续二创，不自研聊天 UI 基础层

#### 2. Flutter 开源项目精选
- GitHub: `Solido/awesome-flutter`
- GitHub: `fluttergems/awesome-open-source-flutter-apps`
- 用途：筛选成熟 UI、上传、播放器、架构实践、工程模板
- 策略：优先从这些索引里选，而不是到处零散搜

#### 3. Dating App 结构参考
- 候选：`helloharendra/Complete-Dating-App`
- 用途：参考滑卡、配对、聊天、资料组织方式
- 策略：借鉴交互和模块拆分，不机械照搬业务代码

## Java / 后端

#### 4. Spring Boot 微服务基础骨架
- 候选：`simovic1/springboot-microservice-starter`
- 候选方向：GitHub topics `spring-boot-microservices`, `spring-boot-kafka`
- 用途：微服务、Kafka、Redis、Docker、Swagger 等基础设施
- 策略：后端先站在成熟骨架上，再替换成春水圈自己的业务模型

#### 5. Kafka / Redis / 事件驱动参考实现
- 候选：`shivk1709/redis-with-kafka`
- 用途：异步消息、服务解耦、缓存协同
- 策略：借基础设施链路，不从零搭消息模式

## 执行方式

### 做新功能前必须回答三件事
1. GitHub 上有没有成熟方案？
2. 能不能直接接？
3. 如果不能直接接，能不能二创？

如果前两项答案不是明确“不能”，就不允许直接进入从零开发。

## 当前落地原则

- 聊天：继续基于 `flutter_chat_ui`
- 社交滑卡 / 页面组织：参考成熟 dating app 开源项目
- 后端基础设施：优先 Spring Boot + Kafka + Redis 成熟模板
- 调度 / 配置 / 注册：直接按 Nacos + XXL-JOB 体系对齐，不自造替代品
- 文件存储：按 AWS S3 兼容能力设计，不自造文件服务协议

## 判断一个开源项目值不值得借

优先看：
- GitHub star / fork / issue 活跃度
- 最近是否仍有维护
- 代码结构是否清晰
- 是否易于裁剪接入
- 是否适合商用和二创

## 当前结论

春水圈后续推进默认采用：
**“顶级开源能力优先，二创优先，集成优先，自研最后。”**

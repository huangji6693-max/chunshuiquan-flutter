# 春水圈 GitHub 开源候选短名单

目标：优先选择可直接接入或适合二创的成熟开源项目，减少从零开发。

## Flutter / 客户端

### 1. flyerhq/flutter_chat_ui
- GitHub: https://github.com/flyerhq/flutter_chat_ui
- 适合方向：聊天 UI、消息渲染、输入区、图片/文件消息、系统消息
- 原因：后端无关、跨平台、可定制、性能导向，且当前春水圈已在使用
- 策略：继续深度二创，不自研聊天基础 UI

### 2. Solido/awesome-flutter
- GitHub: https://github.com/Solido/awesome-flutter
- 适合方向：筛选高质量 Flutter 库、架构方案、UI 组件、工具链
- 原因：是索引型仓库，适合作为后续选型入口
- 策略：后续新需求先从这里找成熟方案

### 3. fluttergems/awesome-open-source-flutter-apps
- GitHub: https://github.com/fluttergems/awesome-open-source-flutter-apps
- 适合方向：参考真实 Flutter 项目结构、业务模块拆分、工程组织方式
- 原因：适合找“真实项目长什么样”而不是只看单个库
- 策略：需要页面/架构参考时优先从这里筛

### 4. helloharendra/Complete-Dating-App
- GitHub: https://github.com/helloharendra/Complete-Dating-App
- 适合方向：滑卡、匹配、聊天入口、社交产品流程
- 原因：是较接近春水圈业务形态的 dating app 开源参考
- 风险：后端栈不同，不能直接照搬
- 策略：重点借 UI 流程、模块拆分、交互设计，不照抄其后端实现

## Java / 后端

### 5. simovic1/springboot-microservice-starter
- GitHub: https://github.com/simovic1/springboot-microservice-starter
- 适合方向：Spring Boot 微服务基础骨架
- 已知能力：Spring Boot 3、Redis、Kafka、Swagger、Docker、Testcontainers、GitHub Actions
- 原因：适合拿来做春水圈后端骨架的起点，而不是从空工程手搓
- 策略：未来若启动后端重构/新仓库，优先基于它做二创

## 选型原则

1. 优先 GitHub 活跃、结构清晰、易裁剪的项目
2. 优先接通用能力，不接强绑定业务黑盒
3. 能二创就不重写
4. 只在春水圈独有业务规则部分做自研

## 当前建议

- 聊天：继续基于 `flyerhq/flutter_chat_ui`
- Dating 交互：参考 `Complete-Dating-App`
- Flutter 组件选型：先看 `awesome-flutter`
- 后端骨架：优先参考 `springboot-microservice-starter`

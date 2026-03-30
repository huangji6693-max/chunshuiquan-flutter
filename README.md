# 春水圈 Flutter App

春水圈移动端 Flutter 工程，包含登录注册、引导页、发现页滑卡、匹配列表、聊天、语音通话、个人资料与设置等基础模块。

## 当前状态

这是一个已搭起主流程骨架的产品原型，不再是 Flutter 默认模板。
当前仓库内已包含：

- 登录 / 注册
- 新用户引导流程
- 发现页与滑卡交互
- 匹配列表与聊天页
- 语音通话页骨架
- 个人资料与设置页
- Dio 网络层与 Token 管理
- Riverpod 状态管理
- Firebase Messaging 接入代码（需完整平台配置）

## 运行前准备

### 1. Flutter 环境

建议使用 Flutter 3.24+ 与 Dart 3.2+

### 2. 安装依赖

```bash
flutter pub get
```

### 3. Firebase 配置

当前仓库已包含 Android 的 `android/app/google-services.json`。
若需完整启用 Firebase / FCM，请继续补齐：

- iOS `GoogleService-Info.plist`
- 对应平台的 Firebase 项目配置
- 如使用 `flutterfire configure`，需同步生成正确配置文件

> 说明：当前代码已做降级处理，Firebase 缺失配置时应用应尽量避免启动即崩。

### 4. 后端地址

默认 API 地址：

```text
https://chunshuiquan-backend-production.up.railway.app
```

也可以通过编译参数覆盖：

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

## 测试

### 单元 / Widget 测试

```bash
flutter test
```

### 集成测试

```bash
flutter test integration_test/smoke_test.dart --device-id=<your-device>
```

## 已知问题

- Firebase 仍缺少完整跨平台配置
- 集成测试目前更适合作为结构性 smoke test，不适合作为稳定 CI 用例
- README、测试与真实产品代码曾有模板残留，正在逐步清理

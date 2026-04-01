# 春水圈 Android 打包指南

## 快速打包（Debug签名，用于测试）

```bash
flutter pub get
flutter build apk --release
```

APK 输出路径: `build/app/outputs/flutter-apk/app-release.apk`

## 正式签名打包（上架 Google Play）

### 1. 生成签名密钥（只需一次）

```bash
keytool -genkey -v -keystore ~/chunshuiquan.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chunshuiquan
```

### 2. 创建 key.properties

在 `android/` 目录下创建 `key.properties`：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=chunshuiquan
storeFile=/Users/你的用户名/chunshuiquan.jks
```

### 3. 打包

```bash
flutter build apk --release          # APK
flutter build appbundle --release     # AAB (Google Play 推荐)
```

## 安装到手机测试

```bash
flutter install --release
# 或手动安装
adb install build/app/outputs/flutter-apk/app-release.apk
```

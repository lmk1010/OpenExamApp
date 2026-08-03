# openexam-app

Flutter（Dart）跨平台项目骨架，支持 Android 与 iOS 打包。

## 为什么选 Flutter？

- **语言**：Dart
- **跨平台**：一套代码同时产出 Android + iOS
- **适合你当前情况**：你已有 `openexam` 业务逻辑，UI 与流程可逐步迁移到 Flutter

## 当前已建好

- `android/` Android 工程
- `ios/` iOS 工程
- `lib/` 分层业务骨架：
  - `app/` 应用入口与路由
  - `core/` 主题、常量等基础层
  - `features/` 功能模块（已含 `home` 与 `exam` 示例）

## 常用命令

```bash
# 安装依赖
flutter pub get

# 本机运行（自动选择设备）
flutter run

# Android 安装包 APK
flutter build apk --release

# Android 上架包 AAB（推荐上架用）
flutter build appbundle --release

# iOS 发布包（需 Xcode + 签名）
flutter build ios --release
```

## 迁移 openexam 建议（下一步）

1. 先迁移题库数据结构（Question/Paper/Record）
2. 把 Electron 的 SQLite 能力换成 Flutter 端 SQLite 插件
3. AI 调用改成服务端中转，避免密钥放在客户端
4. 再迁移做题页、错题本、统计页

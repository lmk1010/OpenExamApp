# 题库产物

`openexam_seed.db.gz` 放在这里，**不进 git，也不进 iOS 包**。

- 46MB 的二进制进版本库，每改一次题库仓库就胖一圈（现在 .git 已经 272MB）；
- 它本来就是产物，`python3 tool/build_seed.py` 能从桌面端仓库重新生成；
- App Store 那个版本不带题库（见 `docs/ios-release.md`），题库留在这里给
  Android 侧载包和自己用的构建。

## 怎么用

```bash
python3 tool/build_seed.py     # 从 ../openexam 重新生成，写到 bank/
python3 tool/bank.py status    # 看当前构建带不带题库
python3 tool/bank.py link      # 放进 assets/seed/，接下来构建就带题库
python3 tool/bank.py unlink    # 拿掉，接下来构建就是空库版
```

`link` 是复制不是软链 —— Flutter 打包时不跟随符号链接。

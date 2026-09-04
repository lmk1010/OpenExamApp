# 设计稿

`openexam-ui.html` 是画布的产物，不入库 —— 改了 `.dc.html` 后重新 seed 就行。

## 母题：上岸

考公的人都说「上岸」。这是中文语境里现成的、带情感的意象，别人抄不走。

| 产品概念 | 视觉 |
| --- | --- |
| 备考过程 | 划船渡海 |
| 每日进度 | 今天划了多少桨 |
| 连续天数 | 灯塔亮了几天 |
| 五个题型 | 五座要经过的岛 |
| 考试日 | 岸 |
| 今日完成 | 靠岸插旗 |

## 色板

底 `#F2F8FC` · 卡 `#FFFFFF` · 主字 `#16232E` · 次字 `#7A8B99`
强调 亮黄 `#FFC94A`（按钮、进度、当前项）· 海蓝 `#1B8FD1`（只给可点文字）
数字用 Outfit，中文 PingFang。

## 间距节奏

顶部留白 36 · 标题组内 5 · 标题组到内容 22
区块之间 30 · 区块标题到内容 11 · 卡内 8–14

区块间距是卡内的两倍多。两个尺度太接近，页面就会摊成一条列表，
再漂亮的组件拼在一起也会觉得诡异。

## 定制组件

母题不能只停在插图里，这四个每天出现几十次的组件都按航海重做：

- **进度条 → 航迹** 虚线是没走的航段，实线带尾流点，船停在当前位置，终点是灯塔
- **勾选 → 救生圈** 圈上四道白色开口是绑绳
- **图文交界 → 水线** 插画没入水里，不是被直线硬切
- **分数环 → 罗盘** 外圈四主四副刻度是度盘

## 素材

`art/` 下 27 个，量化后约 730 KB。三套风格锁在 `gen_scenes.py` 里，
加新的只写一行主体描述即可：

- `STYLE_DAY` 晴天海场景，给日常界面（620px jpg）
- `STYLE_BADGE` 圆形奖章形制，给成就（320px png）
- `STYLE_ICON` 立体小图标，给入口（320px png）

规格必须锁死。上一版每张图各生成各的，结果四屏四种画风，
放一起就散了 —— 协调感的唯一来源是「一整套图出自同一个绘者」。

重新生成：

```bash
export OPENEXAM_IMAGE_KEY=sk-...        # 出图服务的 key，别提交
python3 design/gen_scenes.py            # 全部
python3 design/gen_scenes.py day_yanyu --force   # 单张重出
```

## 重新 seed 画布

```bash
B=<design skill 的 base 目录>
node "$B/seed-canvas.mjs" --template "$B/payload.template.html" \
  --out design/openexam-ui.html --title "OpenExam UI" \
  $(for f in design/*.dc.html; do printf -- "--artboard %s " "$f"; done) \
  $(for f in design/art/*; do printf -- "--image %s " "$f"; done) \
  --canvas design/canvas.json
```

## 还没做

- 深色主题（`Dark.dc.html` 是旧色板，待按上面这套对齐）
- 题库详情、导入、备份等次级页面

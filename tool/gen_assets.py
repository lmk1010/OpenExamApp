#!/usr/bin/env python3
"""
批量生成 app 素材图。

  export OPENEXAM_IMAGE_KEY=sk-...
  export OPENEXAM_IMAGE_BASE=https://988665.xyz/v1     # 可选
  python3 tool/gen_assets.py                           # 生成全部待补素材
  python3 tool/gen_assets.py empty_essay empty_vocab   # 只生成指定几张
  python3 tool/gen_assets.py --list                    # 看有哪些
  python3 tool/gen_assets.py --model grok-imagine-image --force

图存到 assets/art/，已存在的默认跳过（--force 覆盖）。
"""
import base64
import json
import os
import sys
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "art"
DEFAULT_MODEL = "gpt-image-2"

# 全套素材共用的风格约束。
#
# 关键是"通透"：主体用白和浅灰撑住体积，颜色只做点缀。
# 之前整套都是深紫高饱和的 glossy 3D，每个图标看着都像同一块紫塑料，
# 铺到界面上就是一片塑料感。
STYLE = (
    "清新通透的立体插画，主体以白色和极浅的灰为主，"
    "只在少数部位点缀柔和的淡紫 #A8A2E8 与淡蓝 #A9C4E8，"
    "哑光材质不要任何强反光和高光点，光线明亮均匀，阴影极淡，"
    "造型简洁圆润，构图疏朗留白充足，透明背景，"
    "无文字无字母无数字，居中构图"
)

# 图标比插画更简、形更实，40px 下也要认得出。
# 同样走浅色通透路线，跟插画是一套语言。
ICON_STYLE = (
    "简洁的立体图标，主体白色或极浅的灰，"
    "只在关键结构上点缀柔和的淡紫 #A8A2E8 或淡蓝 #A9C4E8，"
    "哑光材质，无反光无高光点，光线柔和均匀，阴影极淡，"
    "形体饱满简洁，透明背景，无文字无字母无数字，居中构图，"
    "小尺寸下依然清晰可辨"
)

ICONS = {
    "ic_achieve":  "一枚奖章，缎带在下方",
    "ic_history":  "一个时钟，表盘上有一圈进度弧",
    "ic_note":     "一本翻开的笔记本，右上角有一支笔",
    "ic_bookmark": "一个书签丝带",
    "ic_report":   "一张文档，上面有一个小柱状图",
    "ic_stats":    "三根高低不同的柱子，旁边一条上扬折线",
    "ic_tips":     "一个亮着的灯泡",
    "ic_fix":      "一支笔在一张纸上打勾修改",
    "ic_plan":     "一块清单板，上面两行打勾",
    "ic_region":   "一个地图定位图钉",
    "ic_calendar": "一个日历，右下角有一个小圆点标记",
    "ic_target":   "一个靶心，中间插着一支箭",
    "ic_stack":    "一摞方块，从大到小叠起",
    "ic_import":   "一个向下的箭头进入托盘",
    "ic_health":   "一个盾牌，中间一个对勾",
    "ic_backup":   "一朵云，下面一个循环箭头",
    "ic_ai":       "一个六边形芯片，四边有引脚",
    "ic_privacy":  "一把闭合的挂锁",
    "ic_about":    "一个圆形徽章，中间是一个竖直的短棒和一个圆点组成的提示标记",
    "ic_theme":    "一个半明半暗的圆，代表日夜切换",
    # 试卷类型：题库列表里每张卷的身份标识
    "ic_exam_nat":   "一枚盾形徽章，中间一颗五角星",
    "ic_exam_prov":  "一张展开的地图，上面一个定位点",
    "ic_exam_joint": "三张卷子并排叠在一起",
    "ic_exam_inst":  "一栋简洁的办公楼，门口一根旗杆",
    "ic_exam_other": "一张卷子，右上角折角",
}

ASSETS = {
    # ── 首页主视觉：作为大卡背景，右侧构图，左边留给文字 ──────────
    "hero_desk":    "一张书桌俯视场景：摊开的笔记本、一支笔、一杯咖啡、一副眼镜，"
                    "内容集中在画面右侧三分之二，左侧大面积留空",
    "hero_focus":   "一个抽象的专注意象：同心圆环与流动的丝带缠绕，中间是一颗星，"
                    "内容集中在右侧，左侧留空",
    "hero_done":    "庆祝场景：一个大对勾徽章，周围散落彩色纸屑和小星星，居中构图",

    # ── 卡片背景纹理：铺在大卡底下，不能抢文字 ────────────────
    "bg_flow":      "极简抽象背景：几条柔和流动的曲线色带交叠，非常淡，没有任何具体物体",
    "bg_grid":      "极简抽象背景：稀疏的点阵与细网格线，非常淡，几何感",

    # ── 五大题型：每个一张小场景图，用在题型宫格里 ──────────────
    "cat_yanyu":    "一个对话气泡和一本翻开的书，代表语言文字理解",
    "cat_shuliang": "一个算盘和几个漂浮的数字符号（加减乘除），代表数学计算",
    "cat_panduan":  "几个几何图形按规律排列，中间一个问号方块，代表图形推理",
    "cat_ziliao":   "一张柱状图和一张折线图叠放，旁边一个放大镜，代表数据分析",
    "cat_changshi": "一个地球仪和一摞书，旁边一个灯泡，代表常识积累",

    # ── 空状态 ───────────────────────────────────────────
    "empty_box":    "一个打开的空纸箱，里面飘出两三个小方块",
    "empty_star":   "一颗描边的星星，周围散着几个小圆点",
    "empty_search": "一个放大镜，镜片是浅紫色半透明玻璃质感（不能是空洞或深色），旁边几条短横线",
    "empty_chart":  "一个空的柱状图坐标轴，只有淡淡的网格线和一条虚线",
    "empty_done":   "一个圆形对勾徽章，周围有庆祝的小碎片",
    "empty_essay":  "一张空白的稿纸和一支钢笔，稿纸上只有淡淡的横格线",
    "empty_vocab":  "几张叠放的词卡，最上面一张是空白的，旁边一个小书签",
    "empty_note":   "一本翻开的笔记本和一支笔，页面空白只有横线",
    "empty_wrong":  "一个圆形里画着一个叉，旁边有一支笔在做订正标记",

    # ── 头像 / 身份 ───────────────────────────────────────
    "avatar_study": "一个正在看书的年轻人半身像，简洁几何造型，没有五官细节，"
                    "只有发型和肩膀的剪影感，居中构图，圆形友好的形态",

    # ── 其他页面的空态 ────────────────────────────────────
    "empty_bank":   "一排书脊整齐排列的书架，其中一格是空的",
    "empty_paper":  "一叠考卷，最上面一张卷角微微翘起",

    # ── 功能入口 ─────────────────────────────────────────
    "hero_essay":   "一只手握笔在稿纸上书写，旁边浮着一个评分气泡",
    "hero_vocab":   "一叠矩形单词卡片呈扇形展开，卡片上只有淡淡的横线，最前面一张微微翘起",
    "hero_plan":    "一个清单板，上面三行待办，前两行已打勾",
}


ASSETS.update(ICONS)


def endpoint() -> str:
    base = os.environ.get("OPENEXAM_IMAGE_BASE", "https://988665.xyz/v1").rstrip("/")
    return f"{base}/images/generations"


def generate(name: str, subject: str, model: str, key: str, force: bool) -> str:
    style = ICON_STYLE if name.startswith("ic_") else STYLE
    out = OUT_DIR / f"{name}.png"
    if out.exists() and not force:
        return f"跳过 {name}（已存在）"

    body = json.dumps({
        "model": model,
        "prompt": f"{subject}。{style}",
        "n": 1,
        "size": "1024x1024",
        # 深色模式下白底会糊成一块白斑，必须让模型直接出透明底
        "background": "transparent",
    }).encode()

    req = urllib.request.Request(
        endpoint(),
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            # 默认的 Python-urllib UA 会被 Cloudflare 以 1010 拦掉
            "User-Agent": "curl/8.7.1",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            payload = json.load(resp)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")[:160]
        return f"失败 {name}: HTTP {exc.code} {detail}"
    except Exception as exc:
        return f"失败 {name}: {exc}"

    item = (payload.get("data") or [{}])[0]
    raw = item.get("b64_json")
    if not raw:
        url = item.get("url")
        if not url:
            return f"失败 {name}: 返回里既没有 b64_json 也没有 url"
        with urllib.request.urlopen(url, timeout=180) as resp:
            data = resp.read()
    else:
        data = base64.b64decode(raw)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out.write_bytes(data)
    return f"完成 {name}  {len(data) // 1024} KB"


def main() -> int:
    argv = sys.argv[1:]
    if "--list" in argv:
        for name, subject in ASSETS.items():
            mark = "有" if (OUT_DIR / f"{name}.png").exists() else "缺"
            print(f"  [{mark}] {name:14} {subject}")
        return 0

    force = "--force" in argv
    argv = [a for a in argv if a != "--force"]

    model = DEFAULT_MODEL
    if "--model" in argv:
        i = argv.index("--model")
        model = argv[i + 1]
        del argv[i:i + 2]

    key = os.environ.get("OPENEXAM_IMAGE_KEY", "").strip()
    if not key:
        print("缺少 OPENEXAM_IMAGE_KEY 环境变量")
        return 1

    wanted = argv or list(ASSETS)
    unknown = [n for n in wanted if n not in ASSETS]
    if unknown:
        print(f"不认识的素材名: {', '.join(unknown)}\n用 --list 看全部")
        return 1

    print(f"模型 {model}，共 {len(wanted)} 张\n")
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(generate, n, ASSETS[n], model, key, force) for n in wanted]
        for future in futures:
            print(" ", future.result())
    return 0


if __name__ == "__main__":
    sys.exit(main())

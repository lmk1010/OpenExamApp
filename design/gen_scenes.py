#!/usr/bin/env python3
"""生成「上岸」母题的场景插画。跟 tool/gen_assets.py 分开：
那套是界面图标，这套是有角色有故事的插图。"""
import base64, json, os, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

OUT = Path(__file__).resolve().parent / "art"

# 统一的插画语言：扁平矢量、有角色、色块大胆、手绘有机感。
# 参照 Silent Moon 那种"一张卡一幅场景"，而不是"一个图标"。
# 一整套图必须出自"同一个绘者"，这是协调感的唯一来源。规格锁死，只换主体。
#
# 两种光：同一个「上岸」母题，日航配浅色主题，夜航配深色主题。
# 上一版把夜海用在了白底首页上 —— 白纸上贴夜景照片，两个世界硬拼。
# 白底要配白天的海，插画和底色得在同一个光线世界里。

STYLE_DAY = (
    "统一的扁平矢量插画风格，明媚的晴天。"
    "色域锁定：天空亮蓝 #7FC4E8 到 #BFE4F5，海水青蓝 #4FB3D9 与 #7FCFE4，"
    "沙岸暖米 #F7E3B0，植物亮绿 #8FCF7A，"
    "亮黄 #FFC94A 用在太阳和高光上，暖橙 #FF9E5E 做少量点缀。"
    "颜色饱和明快，画面通透明亮，没有灰调没有暗部，像晴天正午。"
    "笔触锁定：干净的色块与简洁曲线，无写实笔触，无照片质感，无渐变噪点。"
    "{compose}"
    "人物简化到只有身形和动作，不画五官。无文字无字母无数字。"
)

STYLE_NIGHT = (
    "统一的扁平矢量插画风格，夜晚。"
    "色域锁定：深夜蓝 #101A31 到 #22355C 的渐层做底，"
    "中景用 #2E4372 与 #3D5891，只用暖黄 #F4D98B 做唯一的点缀光。"
    "笔触锁定：干净的色块与简洁曲线，无写实笔触，无照片质感，无强光晕。"
    "{compose}"
    "人物简化到只有身形和动作，不画五官。无文字无字母无数字。"
)

# 徽章单独一套：圆形奖章形制，比场景插画更实、更小，
# 40–56px 下要认得出。每枚各画各的，不能是同一个图标换颜色。
STYLE_BADGE = (
    "{compose}"
    "一枚圆形奖章，正面视角，居中构图，四周透明背景。"
    "奖章底盘是暖黄 #FFC94A 到 #FFD97A 的渐层，外圈一道细的深金 #C9922B 描边，"
    "章面主体图形用海蓝 #2E6FD9 与白色，少量浅青 #7FCFE4 点缀。"
    "扁平矢量风格，干净的色块，无写实笔触无强反光，形体饱满简洁。"
    "无文字无字母无数字。"
)

# 界面图标：比徽章更简，40px 下要认得出。跟徽章同一个色系但不做奖章形制。
STYLE_ICON = (
    "{compose}"
    "一个简洁的立体小图标，居中构图，透明背景。"
    "主体用海蓝 #2E6FD9 与白色，暖黄 #FFC94A 做一处点缀，浅青 #7FCFE4 做阴影面。"
    "扁平矢量风格，干净的色块，圆润饱满，无写实笔触无强反光。"
    "造型极简，小尺寸下依然清晰可辨。无文字无字母无数字。"
)

# 两种构图：主视觉要在上方留白给文字；岛卡尺寸小，主体必须占满才认得出。
COMPOSE_HERO = "构图锁定：主体位于画面下方三分之一，上方三分之二留空给文字。"
COMPOSE_TILE = "构图锁定：主体居中并占满画面大部分，四周只留一点点余量，主体要足够大足够清晰。"

TILE = ("yanyu", "shuliang", "panduan", "ziliao", "changshi")

SCENES = {
    # ── 夜航：引导页与今日靠岸，一次性的情绪时刻 ──
    "night_voyage": "一个人独自划着小木船在夜海上前行，远处岬角有一座亮着暖黄灯的灯塔",
    "night_arrive": "一叶小船停靠在夜色的沙岸边，岸上立着一面小旗，天边刚泛起一线暖黄的曙光",
    "night_calm": "平静无人的夜海，只有一圈涟漪和水面上一道暖黄的月光倒影",

    # ── 日航：日常四屏，跟白底同一个光线世界 ──
    "day_voyage": "清晨明亮的海面上一个人划着小木船前行，远处有一座白色的灯塔，天上几朵蓬松的白云",
    "day_yanyu": "清晨明亮的海上一座小岛，岛上一个人坐在一摞书上读书，几只白鸟绕着飞",
    "day_shuliang": "晴天的海上一座小岛，岛上立着一把木质大算盘，算珠是亮黄色，一个人站在旁边",
    "day_panduan": "清晨明亮的海上一座小岛，岛上悬浮着一组排成阵列的几何图形，一个人举着放大镜看它们",
    "day_ziliao": "清晨明亮的海上一座小岛，岛上是由高低柱状图组成的山峰，一个人站在最高处眺望",
    "day_changshi": "清晨明亮的海上一座小岛，岛上一个人靠着一个大地球仪看书，旁边有几株植物",
    "day_calm": "晴天平静无人的海面，只有一圈涟漪和几朵倒映的白云",
    "day_badge": "晴天的海边礁石上立着一座亮黄色的小灯塔，塔顶挂着一枚圆形徽章，海鸥绕着飞",
    "day_log": "晴天的沙滩上摊开一本航海日志，旁边放着一支笔和一个黄铜罗盘",
    "day_chart": "晴天的桌面上摊开一张海图，图上画着航线和几座岛，压着一把尺和一枚放大镜",
    "day_essay": "晴天的海边一个人伏在木桌上写字，桌上一摞稿纸，旁边一支笔和一杯水",

    # ── 成就徽章：每枚各画各的 ──
    "badge_first":  "章面是一叶扬帆的小船，船头激起一点浪花",
    "badge_week":   "章面是七颗排成弧线的小星星，中间一弯月牙",
    "badge_kilo":   "章面是一摞书，书上立着一面小旗",
    "badge_perfect":"章面是一个大对勾，两侧各一片橄榄枝",
    "badge_dawn":   "章面是海平线上升起的半个太阳，下面三道水波",
    "badge_shore":  "章面是一座灯塔立在礁石上，塔顶射出两道光",

    # ── 「我的」宫格图标 ──
    "ico_achieve": "一枚带缎带的小奖章",
    "ico_history": "一个航海用的沙漏",
    "ico_note":    "一本翻开的航海日志，上面搁着一支笔",
    "ico_mark":    "一枚书签丝带",
    "ico_report":  "一卷摊开的卷轴，上面一个小柱状图",
    "ico_stats":   "一张折起一角的海图，上面一条上扬的航线",
    "ico_tips":    "一个航海用的黄铜罗盘",
    "ico_fix":     "一支笔在纸上打勾修改",
    "day_start": "晴天的海面上一个人划着小木船出发，远处是一座亮黄色的灯塔，天上飘着蓬松的白云，海鸥在飞",
    "day_arrive": "晴天的沙岸边停着一叶小船，沙丘上立着一面亮黄色的旗子迎风飘，天空明亮有大片白云",
}


def gen(name: str, subject: str, key: str, force: bool) -> str:
    out = OUT / f"{name}.png"
    if out.exists() and not force:
        return f"跳过 {name}"
    body = json.dumps({
        "model": "gpt-image-2",
        "prompt": f"{subject}。" + (
            STYLE_BADGE if name.startswith("badge") else
            STYLE_ICON if name.startswith("ico_") else
            STYLE_DAY if name.startswith("day") else STYLE_NIGHT
        ).format(
            compose="" if name.startswith("badge") or name.startswith("ico_")
            else COMPOSE_TILE if any(k in name for k in TILE)
            else COMPOSE_HERO
        ),
        "n": 1,
        "size": "1024x1024",
    }).encode()
    req = urllib.request.Request(
        os.environ.get("OPENEXAM_IMAGE_BASE", "https://988665.xyz/v1").rstrip("/") + "/images/generations",
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "User-Agent": "curl/8.7.1",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=240) as resp:
            payload = json.load(resp)
    except urllib.error.HTTPError as exc:
        return f"失败 {name}: HTTP {exc.code} {exc.read().decode(errors='replace')[:120]}"
    except Exception as exc:
        return f"失败 {name}: {exc}"

    item = (payload.get("data") or [{}])[0]
    raw = item.get("b64_json")
    if not raw:
        return f"失败 {name}: 返回里没有图"
    OUT.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(raw))
    return f"完成 {name}  {out.stat().st_size // 1024} KB"


def main() -> int:
    key = os.environ.get("OPENEXAM_IMAGE_KEY", "").strip()
    if not key:
        print("缺少 OPENEXAM_IMAGE_KEY")
        return 1
    argv = [a for a in sys.argv[1:] if a != "--force"]
    force = "--force" in sys.argv
    wanted = argv or list(SCENES)
    with ThreadPoolExecutor(max_workers=3) as pool:
        for fut in [pool.submit(gen, n, SCENES[n], key, force) for n in wanted]:
            print(" ", fut.result())
    return 0


if __name__ == "__main__":
    sys.exit(main())

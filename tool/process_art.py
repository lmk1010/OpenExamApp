#!/usr/bin/env python3
"""
把生成的白底大图处理成 app 能直接用的素材：
  1. 裁掉四周多余留白，按内容重新居中
  2. 缩到 512，量化压缩

出图时已经带透明底了（gen_assets 传 background=transparent），
这里不要再做抠白 —— 插画主体本身就是浅色纸张，抠白会把主体一起抠没。

  python3 tool/process_art.py            # 处理 assets/art 下所有图
  python3 tool/process_art.py --size 384
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"

def trim(img: Image.Image, pad_ratio: float = 0.04) -> Image.Image:
    box = img.getbbox()
    if not box:
        return img
    img = img.crop(box)
    # 补一圈留白，免得贴边
    pad = int(max(img.size) * pad_ratio)
    canvas = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    canvas.paste(img, (pad, pad))
    return canvas


def square(img: Image.Image) -> Image.Image:
    side = max(img.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
    return canvas


def main() -> int:
    size = 512
    if "--size" in sys.argv:
        size = int(sys.argv[sys.argv.index("--size") + 1])

    files = sorted(ART.glob("*.png"))
    # 图标只在 40-56px 显示，512 是浪费；插画会做大所以留 512
    if not files:
        print("assets/art 下没有图，先跑 tool/gen_assets.py")
        return 1

    total_before = total_after = 0
    for path in files:
        before = path.stat().st_size
        img = Image.open(path)
        img = square(trim(img.convert("RGBA")))
        target = 256 if path.stem.startswith("ic_") else size
        img = img.resize((target, target), Image.LANCZOS)
        # 量化到 256 色，插画色数少，肉眼看不出差别，体积能降一个数量级
        img = img.quantize(colors=256, method=Image.FASTOCTREE).convert("RGBA")
        img.save(path, "PNG", optimize=True)
        after = path.stat().st_size
        total_before += before
        total_after += after
        print(f"  {path.name:16} {before // 1024:>4} KB → {after // 1024:>3} KB")

    print(f"\n合计 {total_before // 1024} KB → {total_after // 1024} KB "
          f"（省了 {100 - total_after * 100 // total_before}%）")
    return 0


if __name__ == "__main__":
    sys.exit(main())

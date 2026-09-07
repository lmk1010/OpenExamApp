#!/usr/bin/env python3
"""带不带内置题库，构建前用这个切。

App Store 那版不打包题库（真题的版权风险 + 90MB 解包体积），Android 侧载包和
自己用的构建带。两者是同一份代码：app 运行时找不到 asset 就开一个空库，不是
编译开关 —— 开关容易和实际打进去的东西对不上，运行时探测不会。

    python3 tool/bank.py status     # 这次构建带不带
    python3 tool/bank.py link       # 带上（Android / 自用）
    python3 tool/bank.py unlink     # 不带（App Store）
"""

from __future__ import annotations

import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
SRC = os.path.join(APP, "bank", "openexam_seed.db.gz")
DST = os.path.join(APP, "assets", "seed", "openexam_seed.db.gz")


def _mb(path: str) -> str:
    return f"{os.path.getsize(path) / 1024 / 1024:.1f}MB"


def status() -> int:
    linked = os.path.exists(DST)
    if linked:
        print(f"带题库 —— assets/seed/ 里有 {_mb(DST)}，构建出来会内置题库")
    else:
        print("不带题库 —— 构建出来是空库版，用户自己导入（App Store 走这个）")
    if not os.path.exists(SRC):
        print("注意：bank/openexam_seed.db.gz 不在，link 之前先跑 tool/build_seed.py")
    return 0


def link() -> int:
    if not os.path.exists(SRC):
        print(f"没有 {SRC}\n先跑：python3 tool/build_seed.py", file=sys.stderr)
        return 1
    # 复制不是软链：Flutter 打包不跟随符号链接，链过去的话 asset 会是空的。
    shutil.copyfile(SRC, DST)
    print(f"已放入 assets/seed/（{_mb(DST)}）—— 接下来构建带题库")
    return 0


def unlink() -> int:
    if os.path.exists(DST):
        os.remove(DST)
        print("已移出 assets/seed/ —— 接下来构建是空库版")
    else:
        print("本来就没有，构建是空库版")
    return 0


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        return status()
    if cmd == "link":
        return link()
    if cmd == "unlink":
        return unlink()
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

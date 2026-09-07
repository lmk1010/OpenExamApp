#!/usr/bin/env python3
"""还有多少中文写死在界面里。

国际化是逐块搬的，中途最怕的是"以为搬完了"。这个脚本按文件列出还没抽走的
中文字符串，数字降到 0 之前就别说做完了。

    python3 tool/i18n_todo.py            # 概览
    python3 tool/i18n_todo.py --list     # 逐条列出
    python3 tool/i18n_todo.py lib/features/wrong   # 只看某个目录
"""

from __future__ import annotations

import os
import re
import sys

# 单/双引号包起来、里面有汉字的字面量。注释整行跳过 —— 注释不需要翻译。
LITERAL = re.compile(r"""(['"])(?:(?!\1|\\).|\\.)*[一-鿿](?:(?!\1|\\).|\\.)*\1""")


def scan(root: str):
    hits: dict[str, list[tuple[int, str]]] = {}
    for base, _, files in os.walk(root):
        for f in files:
            if not f.endswith('.dart'):
                continue
            path = os.path.join(base, f)
            # 生成物和 arb 本身不算
            if '/l10n/' in path.replace(os.sep, '/'):
                continue
            found = []
            for n, line in enumerate(open(path, encoding='utf-8'), 1):
                stripped = line.strip()
                if stripped.startswith('//'):
                    continue
                for m in LITERAL.finditer(line):
                    found.append((n, m.group(0)))
            if found:
                hits[path] = found
    return hits


ARB_ZH = 'lib/l10n/app_zh.arb'
ARB_EN = 'lib/l10n/app_en.arb'


def check_arbs() -> int:
    """英文那份翻全了没有。

    这条是必查的：gen-l10n 遇到英文缺 key **不报错**，直接回落成模板里的
    中文。界面上看见的就是「按钮是英文、正文是中文」这种夹生状态，源码里
    一处写死的中文都找不到 —— 只扫 .dart 永远发现不了。
    """
    import json

    zh = json.load(open(ARB_ZH, encoding='utf-8'))
    en = json.load(open(ARB_EN, encoding='utf-8'))
    keys = lambda d: {k for k in d if not k.startswith('@')}
    missing = sorted(keys(zh) - keys(en))
    extra = sorted(keys(en) - keys(zh))
    untranslated = sorted(
        k for k in keys(en) & keys(zh)
        if isinstance(en[k], str) and re.search('[一-鿿]', en[k])
    )

    bad = 0
    if missing:
        bad += len(missing)
        print(f'app_en.arb 缺 {len(missing)} 个 key（会静默回落成中文）：')
        for k in missing[:20]:
            print(f'        {k}  ← {zh[k]!r}')
    if untranslated:
        bad += len(untranslated)
        print(f'app_en.arb 里还有 {len(untranslated)} 条带汉字：')
        for k in untranslated[:20]:
            print(f'        {k}  = {en[k]!r}')
    if extra:
        print(f'（app_en.arb 多出 {len(extra)} 个 key，中文那份没有：{extra[:5]}）')
    if not bad:
        print(f'arb 对得上：{len(keys(zh))} 个 key，英文全译。')
    return bad


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    root = args[0] if args else 'lib'
    verbose = '--list' in sys.argv

    bad = check_arbs()
    print()

    hits = scan(root)
    total = sum(len(v) for v in hits.values())
    if not hits:
        print(f'{root}: 没有写死的中文了')
        return 1 if bad else 0

    for path in sorted(hits, key=lambda p: -len(hits[p])):
        print(f'{len(hits[path]):5d}  {path}')
        if verbose:
            for n, text in hits[path]:
                print(f'        {n}: {text}')
    print(f'\n合计 {total} 处，分布在 {len(hits)} 个文件')
    return 1 if bad else 0


if __name__ == '__main__':
    raise SystemExit(main())

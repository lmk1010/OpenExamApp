#!/usr/bin/env python3
"""把一个文件里的中文界面文案换成 AppL 调用，并写进两份 arb。

用法是喂一份 JSON：

    [
      {"file": "lib/features/x/y.dart",
       "ctx": "l",
       "items": [
         {"zh": "'导入题库'", "key": "importBank", "en": "Import a bank"},
         {"zh": "'共 $n 题'", "key": "totalCount", "en": "{count} questions",
          "zh_text": "共 {count} 题", "call": "l.totalCount(n)",
          "placeholders": {"count": {"type": "int"}}}
       ]}
    ]

`zh` 是**源码里原样的那段**（含引号，可以是多行相邻字面量拼接）；没给 `call`
就默认换成 `AppL.of(context).<key>`。带占位符的必须自己给 `call`，因为参数名
只有调用处知道。

默认不生成 `l.<key>`：那要求每个用到的方法里先 `final l = AppL.of(context);`，
一个文件要来回好几趟补绑定。`AppL.of(context)` 只要 context 在作用域里就行 ——
State 的方法和 build 里永远成立，正好覆盖绝大多数界面文案。
`ctx` 传别的名字（比如已经绑好 `l` 的文件）才走 `<ctx>.<key>`。

替换是精确字符串匹配、每条只换第一处 —— 匹配不上直接报错退出，绝不模糊匹配。
国际化最怕的是"换错了但还能编译"。
"""

from __future__ import annotations

import json
import re
import sys
from collections import OrderedDict

ZH_ARB = 'lib/l10n/app_zh.arb'
EN_ARB = 'lib/l10n/app_en.arb'
IMPORT = "import 'package:openexam_app/l10n/app_localizations.dart';"

# arb 里的值不带引号，源码里的字面量要剥掉外层引号并把相邻字面量拼起来。
LITERAL = re.compile(r"""'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)\"""")


def unquote(src: str) -> str:
    """把源码里的（可能多段相邻的）字符串字面量还原成纯文本。"""
    parts = [m.group(1) if m.group(1) is not None else m.group(2)
             for m in LITERAL.finditer(src)]
    if not parts:
        raise SystemExit(f'不是字符串字面量：{src[:60]}')
    return ''.join(parts).replace(r"\'", "'").replace(r'\"', '"')


def load(path: str) -> OrderedDict:
    with open(path, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def dump(path: str, data) -> None:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


# `const Text('中文')` 换成方法调用后就不再是常量表达式，得把 const 去掉。
# 只动**紧跟着构造函数**的那个 const：`const x = ...` 是变量声明，删掉它
# 声明就没了 —— 上一版盲删就干过这事，把 `const modes = [` 删成了 `modes = [`。
CONST_DECL = re.compile(r'\bconst\s+\w+\s*=')


def strip_const_before(src: str, index: int) -> str:
    """把 index 处表达式前面那个多余的 const 去掉。"""
    head = src[:index]
    pos = head.rfind('const ')
    if pos < 0:
        return src
    # 中间隔了分号或右括号，说明那个 const 管的是别的表达式
    between = head[pos + 6:]
    if ';' in between:
        return src
    if CONST_DECL.match(src[pos:]):
        return src
    return src[:pos] + src[pos + 6:]


def main() -> int:
    spec = json.load(open(sys.argv[1], encoding='utf-8'))
    zh, en = load(ZH_ARB), load(EN_ARB)
    changed = 0

    # 先把所有 key 冲突查一遍，再动任何文件。
    #
    # 以前是边改源码边攒 arb，arb 最后一次性写盘 —— 中途任何一条报错，
    # 源码已经改了一半、arb 一个字没写，留下一堆 undefined_getter。
    seen = dict(zh)
    for entry in spec:
        for item in entry['items']:
            key = item['key']
            text = item.get('zh_text', unquote(item['zh']))
            if key in seen and seen[key] != text:
                raise SystemExit(
                    f'{key} 已存在且内容不同，换个 key\n'
                    f'  已有: {seen[key]}\n  这次: {text}'
                )
            seen[key] = text

    for entry in spec:
        path = entry['file']
        ctx = entry.get('ctx')
        src = open(path, encoding='utf-8').read()

        for item in entry['items']:
            key, raw = item['key'], item['zh']
            # 同一句在一个文件里出现多次是常事（每条 item 只换一处），
            # 所以重名不是错 —— 内容对得上就是同一句。比的必须是最终写进
            # arb 的那个值，不是源码原文，否则带占位符的会被误判成冲突。
            text = item.get('zh_text', unquote(raw))
            if key in zh and zh[key] != text:
                raise SystemExit(f'{key} 已存在且内容不同，换个 key')
            # 相邻字面量之间的换行和缩进按源码原样写太脆 —— 差两个空格就
            # 匹配不上。按字面量分段找，段与段之间允许任意空白。
            pattern = re.compile(
                r'\s*'.join(
                    re.escape(m.group(0)) for m in LITERAL.finditer(raw)
                )
            )
            hit = pattern.search(src)
            if hit is None:
                raise SystemExit(f'{path}: 找不到\n{raw[:120]}')

            # Dart 里相邻的字符串字面量会自动拼接，但表达式不会。只换掉其中
            # 一半，剩下的就变成两个并排的表达式，编译直接挂：
            #     body: l.a(x)
            #         l.b,          // ← 少了个逗号？不，是本来该拼在一起
            # 所以匹配段紧邻另一个字面量时必须报错 —— 那说明这一条要连着
            # 邻居一起写进 zh，不能拆开换。
            after = src[hit.end():hit.end() + 200].lstrip()
            before = src[:hit.start()].rstrip()
            if after[:1] in ("'", '"') or before[-1:] in ("'", '"'):
                raise SystemExit(
                    f'{path}: 这段两边还连着别的字符串字面量，'
                    f'要连邻居一起写进同一条 zh：\n{raw[:120]}'
                )
            raw = hit.group(0)
            call = item.get(
                'call',
                f'{ctx}.{key}' if ctx else f'AppL.of(context).{key}',
            )
            at = src.index(raw)
            src = src.replace(raw, call, 1)
            if item.get('const', True):
                src = strip_const_before(src, at)
            # 带插值的必须显式给 zh_text：源码里是 Dart 的 `$n` / `${a.b}`，
            # arb 要的是 ICU 的 `{count}`。照抄源码的话，中文界面会原样显示
            # 「已导入 $added 道题」，而 `${...}` 的花括号还会直接把 ICU
            # 解析搞崩 —— 那次整份 arb 都生成不出来。
            zh[key] = text
            en[key] = item['en']
            if 'placeholders' in item:
                zh[f'@{key}'] = {'placeholders': item['placeholders']}
            changed += 1

        if IMPORT not in src:
            lines = src.split('\n')
            for i, line in enumerate(lines):
                if line.startswith("import 'package:openexam_app/"):
                    lines.insert(i, IMPORT)
                    break
            src = '\n'.join(lines)
        open(path, 'w', encoding='utf-8').write(src)
        print(f'ok  {path}  ({len(entry["items"])} 条)')

    dump(ZH_ARB, zh)
    dump(EN_ARB, en)
    print(f'共 {changed} 条写入 arb')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

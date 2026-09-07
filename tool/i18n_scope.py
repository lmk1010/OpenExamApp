#!/usr/bin/env python3
"""把待国际化的中文分成两堆：界面文案 vs 中文考试内容。

「全部翻译」在这个 app 里是个错误目标。库里有一大堆中文本身就是**内容**：
成语辨析（逻辑填空考的就是中文用法）、行测五模块的解题方法、申论批改提示词。
把「一蹴而就 / 多用于否定」翻成英文，对谁都没有意义 —— 它不是界面，是题材。

这些应该跟着题库和备考目标走（ExamProfile 已经在按开关隐藏了），而不是跟着
界面语言走。真正要翻的是**界面本身**：按钮、标题、提示、空状态。
"""

from __future__ import annotations

import sys

sys.path.insert(0, __import__('os').path.dirname(__file__))
from i18n_todo import scan  # noqa: E402

# 中文考试内容，不翻译 —— 换一门考试它们本来就该整块换掉或隐藏。
CONTENT = {
    'lib/features/vocab/data/vocab_seed.dart': '成语词表：考的就是中文用法',
    'lib/features/tips/tips.dart': '行测五模块的解题方法和真题基准',
    'lib/features/plan/data/starter_packs.dart': '中文备考计划模板',
    'lib/features/essay/data/essay_grader.dart': '申论批改提示词',
    'lib/core/constants/categories.dart': '行测模块名（非行测题库走题库自己的分类）',
    # 诊断里剩下的中文是行测专属处方（「逻辑填空练搭配不背释义」）和喂给模型的
    # 行测知识 —— 只在 Benchmark 认得的模块上触发，也就是只在行测题库下出现。
    'lib/features/diagnosis/diagnosis.dart': '行测专属处方 + 模型系统提示',
}


def main() -> int:
    hits = scan('lib')
    chrome, content = {}, {}
    for path, items in hits.items():
        rel = path.replace('\\', '/')
        (content if rel in CONTENT else chrome)[rel] = items

    def total(d):
        return sum(len(v) for v in d.values())

    print('== 中文考试内容（不翻译） ==')
    for p in sorted(content, key=lambda x: -len(content[x])):
        print(f'{len(content[p]):5d}  {p}\n         {CONTENT[p]}')
    print(f'         小计 {total(content)} 处\n')

    print('== 界面文案（要翻译） ==')
    for p in sorted(chrome, key=lambda x: -len(chrome[x]))[:15]:
        print(f'{len(chrome[p]):5d}  {p}')
    print(f'         …共 {len(chrome)} 个文件，小计 {total(chrome)} 处')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

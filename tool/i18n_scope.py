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
    # 剩下的全是 SQL LIKE 模式和中文省份名 —— 拿去 contains 匹配中文卷名的，
    # 翻了会直接把地区分类打断。跟 bank_page 里的「国考/联考」同一类。
    'lib/data/db/app_database.dart': '匹配中文卷名的 SQL 模式与省份名',
    # 中文 CSV 的列名（题干/答案/选项a）和分类猜测关键词，拿去匹配用户导入的
    # 文件表头 —— 翻了中文 CSV 就导不进来了。
    'lib/data/importers/question_importer.dart': '中文 CSV 列名与分类关键词',
    # 喂给视觉模型的提示词和 JSON schema 描述，是给模型的指令不是界面。
    'lib/features/import/data/paper_scanner.dart': '视觉模型提示词',
    # 剩下的是「国考/联考/事业/选调」这批 —— 拿去 contains 匹配中文卷名的
    # key 和 switch 分支，决定试卷分类、图标和配色，翻了直接打断。
    'lib/features/bank/bank_page.dart': '匹配中文卷名的地区/考试类型 key',
    # 拼给模型的题目上下文和禁用套话表（「这是一道很好的题」那种），
    # 是给模型的指令不是界面。
    'lib/features/ai/ai_explain_panel.dart': '讲题提示词与禁用套话表',
    # 搜索建议词（主旨概括/等差数列/行政处罚）是给这个题库用的例子，
    # 该跟题库语言走，不跟界面语言走。
    'lib/features/search/search_page.dart': '搜索建议词',
    # 申论的五种题型（归纳概括/提出对策/综合分析/贯彻执行/大作文）——
    # 跟行测模块名一样，是这门考试自己的分类。
    'lib/features/essay/domain/essay_models.dart': '申论题型名',
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

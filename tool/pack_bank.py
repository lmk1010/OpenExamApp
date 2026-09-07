#!/usr/bin/env python3
"""把种子库切成几个能下载、能导入的题库包。

App 现在不带题库了（App Store 走空库版），题库从官网下。这个脚本把
`bank/openexam_seed.db.gz` 按报考地区切成几个包，每个包就是一个 zip：

    <包>/
      <卷名>.json      每张卷一份，格式跟 QuestionImporter 吃的完全一样
      images/*.png     只放这个包里真用到的图

**格式必须跟 App 的导出格式一致**，否则用户下下来导不进去。对照
lib/features/bank/bank_export.dart 和 lib/data/importers/question_importer.dart：
zip 里任意深度的 *.json 都会被读，多份会合并；题里带了 paperId/paperTitle/year
就用题自己的，所以一个包放多张卷没问题。

    python3 tool/pack_bank.py            # 全部包 + manifest
    python3 tool/pack_bank.py --list     # 只看会打出什么，不落盘
"""

from __future__ import annotations

import gzip
import hashlib
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
SEED = os.path.join(APP, "bank", "openexam_seed.db.gz")
OUT = os.path.join(APP, "dist", "banks")

# 认卷名用的地区词表。跟 lib/core/constants/categories.dart 的 kProvinces
# 是同一张表 —— 改一边必须改另一边，否则官网切出来的包和 App 里的地区
# 筛选对不上。
PROVINCES = [
    "国考", "北京", "上海", "广东", "江苏", "浙江", "山东", "河南", "河北",
    "四川", "湖北", "湖南", "安徽", "福建", "江西", "陕西", "山西", "辽宁",
    "吉林", "黑龙江", "云南", "贵州", "广西", "天津", "重庆", "内蒙古",
    "新疆", "甘肃", "海南", "宁夏", "青海", "西藏",
]


def region_of(title: str) -> str:
    if "国家公务员" in title or "国考" in title:
        return "国考"
    for p in PROVINCES:
        if p != "国考" and p in title:
            return p
    if "联考" in title:
        return "联考"
    if "事业单位" in title or "事业编" in title:
        return "事业"
    if "选调" in title:
        return "选调"
    return "其他"


# 要打哪几个包。keep 收到一个地区名，返回这张卷进不进这个包。
PACKS = [
    {
        "slug": "gongkao-national",
        "name": "国考行测真题",
        "exam": "考公",
        "blurb": "国家公务员考试行政职业能力测验，省级与地市级卷。",
        "keep": lambda r: r == "国考",
    },
    {
        "slug": "gongkao-province",
        "name": "省考行测真题",
        "exam": "考公",
        "blurb": "各省省考与联考行测卷，覆盖三十余个省份。",
        "keep": lambda r: r not in ("国考", "其他"),
    },
]


def open_seed() -> tuple[sqlite3.Connection, str]:
    if not os.path.exists(SEED):
        print(f"没有 {SEED}\n先跑：python3 tool/build_seed.py", file=sys.stderr)
        raise SystemExit(1)
    tmp = tempfile.mktemp(suffix=".db")
    with gzip.open(SEED, "rb") as f, open(tmp, "wb") as o:
        shutil.copyfileobj(f, o)
    db = sqlite3.connect(tmp)
    db.row_factory = sqlite3.Row
    return db, tmp


def question_json(row: sqlite3.Row, material: str) -> dict:
    """一道题的 JSON。字段名跟 Question.toJson() 一致。"""
    out = {
        "id": row["id"],
        "content": row["content"] or "",
        "contentHtml": row["content_html"] or "",
        "options": json.loads(row["options"] or "[]"),
        "answer": (row["answer"] or "").upper(),
        "category": row["category"] or "",
        "subCategory": row["sub_category"] or "",
        "analysis": row["analysis"] or "",
        "analysisHtml": row["analysis_html"] or "",
        "paperId": row["paper_id"] or "",
        "paperTitle": row["paper_title"] or "",
        "year": row["year"] or 0,
        "difficulty": row["difficulty"] or 0,
        # source 不写：导入器一律改写成 imported，写了也是白写。
        "orderNum": row["order_num"] or 0,
    }
    if (row["type"] or "single") == "multiple":
        out["isMulti"] = True
    if row["material_id"]:
        out["materialId"] = row["material_id"]
    if material:
        out["material"] = material
    return out


IMG = None


def image_names(blobs: list[str]) -> set[str]:
    global IMG
    if IMG is None:
        import re
        IMG = re.compile(r"oeimg://([A-Za-z0-9._-]+)")
    names = set()
    for b in blobs:
        if b:
            names.update(IMG.findall(b))
    return names


def safe(name: str) -> str:
    out = "".join("-" if c in '\\/:*?"<>| \t' else c for c in name)
    while "--" in out:
        out = out.replace("--", "-")
    return out.strip("-") or "paper"


def build(db: sqlite3.Connection, pack: dict, dry: bool) -> dict:
    materials = {
        r["id"]: r["content_html"] or r["content"] or ""
        for r in db.execute("SELECT id, content, content_html FROM materials")
    }

    papers: dict[str, list[sqlite3.Row]] = {}
    for row in db.execute(
        "SELECT * FROM questions WHERE paper_id IS NOT NULL AND paper_id != ''"
        " ORDER BY paper_id, order_num"
    ):
        if not pack["keep"](region_of(row["paper_title"] or "")):
            continue
        papers.setdefault(row["paper_id"], []).append(row)

    total = sum(len(v) for v in papers.values())
    years = sorted({r["year"] for rows in papers.values() for r in rows if r["year"]})
    wanted: set[str] = set()
    files: list[tuple[str, str]] = []

    for pid, rows in papers.items():
        items = []
        for r in rows:
            mat = materials.get(r["material_id"] or "", "")
            item = question_json(r, mat)
            items.append(item)
            wanted |= image_names([
                item["contentHtml"], item["content"], item["analysisHtml"],
                mat, json.dumps(item["options"], ensure_ascii=False),
            ])
        title = rows[0]["paper_title"] or pid
        body = {
            "paper": {"id": pid, "title": title, "year": rows[0]["year"] or 0},
            "questions": items,
        }
        files.append((
            f"{safe(title)}-{pid[:6]}.json",
            json.dumps(body, ensure_ascii=False, separators=(",", ":")),
        ))

    info = {
        "slug": pack["slug"],
        "name": pack["name"],
        "exam": pack["exam"],
        "blurb": pack["blurb"],
        "papers": len(papers),
        "questions": total,
        "images": len(wanted),
        "years": [years[0], years[-1]] if years else [],
    }

    if dry:
        return info

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"{pack['slug']}.zip")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, text in files:
            z.writestr(name, text)
        if wanted:
            marks = ",".join("?" * len(wanted))
            for r in db.execute(
                f"SELECT name, bytes FROM images WHERE name IN ({marks})",
                sorted(wanted),
            ):
                # 图片本身已经是压缩过的，再 deflate 只是白费 CPU。
                z.writestr(f"images/{r['name']}.png", r["bytes"],
                           compress_type=zipfile.ZIP_STORED)

    data = open(path, "rb").read()
    info["file"] = os.path.basename(path)
    info["bytes"] = len(data)
    info["sha256"] = hashlib.sha256(data).hexdigest()
    return info


def main() -> int:
    dry = "--list" in sys.argv
    db, tmp = open_seed()
    try:
        out = [build(db, p, dry) for p in PACKS]
    finally:
        db.close()
        os.remove(tmp)

    for i in out:
        size = f"{i['bytes'] / 1024 / 1024:.1f}MB" if "bytes" in i else "—"
        span = f"{i['years'][0]}–{i['years'][1]}" if i["years"] else "?"
        print(f"{i['slug']:20s} {i['papers']:4d} 卷 {i['questions']:6d} 题 "
              f"{i['images']:5d} 图  {span}  {size}")

    if not dry:
        man = os.path.join(OUT, "manifest.json")
        json.dump({"packs": out}, open(man, "w", encoding="utf-8"),
                  ensure_ascii=False, indent=2)
        print(f"\n→ {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

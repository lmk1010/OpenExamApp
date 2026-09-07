#!/usr/bin/env python3
"""Build the mobile seed database from the OpenExam desktop seed.

Reads ../openexam/data/openexam.seed.db (+ data/question-assets) and writes a
ready-to-open SQLite file with the mobile schema, images embedded as BLOBs, then
gzips it into bank/ (run tool/bank.py link to bundle it). The app decompresses it on first launch, so there is
no runtime download and no network access at all.

    python3 tool/build_seed.py [--limit N]
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
DESKTOP = os.path.join(os.path.dirname(APP), "openexam")
SRC_DB = os.path.join(DESKTOP, "data", "openexam.seed.db")
SRC_DB_GZ = SRC_DB + ".gz"
ASSET_DIR = os.path.join(DESKTOP, "data", "question-assets")
# 产物落在 bank/，不落 assets/ —— assets/ 里有没有它决定这次构建带不带题库，
# 由 tool/bank.py 管。生成完要 `python3 tool/bank.py link` 才会打进包里。
OUT_GZ = os.path.join(APP, "bank", "openexam_seed.db.gz")

ASSET_REF = re.compile(r"openexam-asset://question-assets/([A-Za-z0-9._-]+)")
TAG = re.compile(r"<[^>]+>")

# 每条解析都以【言语理解/yueduan】这样一个内部标签开头 —— 18686 条无一例外，
# 而且斜杠后面那截跟 sub_category 列一字不差。分类页头上已经写着「言语理解」，
# 这里再挂一遍拼音 slug 只是把调试信息晒给用户看。
ANALYSIS_TAG = re.compile(r"^(\s*(?:<[^>]+>\s*)*)【[^】/]*/[A-Za-z_]+】\s*")

# 填空题的空，上游写成 <u> 一串空格 </u>。app 的富文本渲染器把所有标签一律
# 剥成纯 Text（没有下划线这一说），plain_text 更是连空格都 strip 掉 —— 于是
# 空在题面上只剩一片空白，在列表预览里干脆消失：有 20 道题的空正好在开头,
# 预览里就成了「的布局模式早已被实践证明是行不通的」这种被砍了头的句子。
#
# 换成下划线字符。这不是新发明 —— 题库里本来就有一千多道题直接用 8~9 个
# 半角下划线表示空，这里只是把两种写法统一过来。
BLANK_UNDERLINE = re.compile(r"<u>\s*</u>", re.IGNORECASE)


def fill_blanks(html: str) -> str:
    return BLANK_UNDERLINE.sub("________", html) if html else html


def resolve_source_db() -> str:
    """The desktop repo ships the seed gzipped; decompress to a temp copy."""
    if os.path.exists(SRC_DB):
        return SRC_DB
    if not os.path.exists(SRC_DB_GZ):
        sys.exit(f"desktop seed not found: {SRC_DB} (or .gz)")
    tmp = os.path.join(tempfile.gettempdir(), "openexam.seed.db")
    if not os.path.exists(tmp) or os.path.getmtime(tmp) < os.path.getmtime(SRC_DB_GZ):
        with gzip.open(SRC_DB_GZ, "rb") as fin, open(tmp, "wb") as fout:
            shutil.copyfileobj(fin, fout)
    return tmp


def asset_index() -> dict[str, str]:
    """Map sha1 basename -> real file (the optimiser rewrote png/jpg to webp)."""
    index: dict[str, str] = {}
    for name in os.listdir(ASSET_DIR):
        index.setdefault(os.path.splitext(name)[0], name)
    return index


def plain_text(html: str) -> str:
    """Readable fallback for list previews and search."""
    if not html:
        return ""
    text = re.sub(r"<br\s*/?>", "\n", html)
    text = re.sub(r"</p>", "\n", text)
    text = TAG.sub("", text)
    text = (
        text.replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", '"')
    )
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def rewrite_assets(html: str, used: set[str]) -> str:
    """openexam-asset://question-assets/x.png -> oeimg://x (stable, ext-free)."""
    if not html:
        return ""

    def sub(match: re.Match[str]) -> str:
        base = os.path.splitext(match.group(1))[0]
        used.add(base)
        return f"oeimg://{base}"

    return ASSET_REF.sub(sub, html)


SCHEMA = """
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  content_html TEXT,
  options TEXT NOT NULL,
  answer TEXT NOT NULL,
  category TEXT,
  sub_category TEXT,
  analysis TEXT,
  analysis_html TEXT,
  paper_id TEXT,
  paper_title TEXT,
  year INTEGER DEFAULT 0,
  difficulty INTEGER DEFAULT 2,
  source TEXT DEFAULT 'builtin',
  has_image INTEGER DEFAULT 0,
  order_num INTEGER DEFAULT 0,
  material_id TEXT DEFAULT '',
  /* 'single' | 'multiple'。上游一直标着，只是以前没带过来 —— 于是 51 道
     答案形如 ABCD 的多选题在单选界面上永远判错，怎么点都是错的。 */
  type TEXT NOT NULL DEFAULT 'single'
);
CREATE INDEX idx_q_cat ON questions(category);
CREATE INDEX idx_q_source ON questions(source);
CREATE INDEX idx_q_paper ON questions(paper_id);
CREATE INDEX idx_q_material ON questions(material_id);

/* 一材多题：资料分析和篇章阅读是一段材料后面跟三到五问。材料存一份、题指
   过去 —— 一段材料上千字, 五题复制五遍既浪费又会在改错时改漏。
   建表语句跟 app 里 _ensureRuntimeTables 那份保持一致, 否则老库升级上来的
   结构和新装的对不上。 */
CREATE TABLE materials (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL DEFAULT '',
  content_html TEXT NOT NULL DEFAULT '',
  paper_id TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT ''
);

/* 高频词表。从 2077 道逻辑填空的选项里统计出来 —— 那些选项本身就是词，
   一道题四个词，不需要分词也不需要词典，数出来的就是真题里的词频。
   4000 多个词、才几百 KB，全存；「高频」是 UI 那边按 count 卡的线。
   sample_question_id 让「这个词考过什么样的题」一点就能跳过去。 */
CREATE TABLE word_freq (
  word TEXT PRIMARY KEY,
  count INTEGER NOT NULL,
  sample_question_id TEXT NOT NULL DEFAULT ''
);
CREATE INDEX idx_word_freq_count ON word_freq(count DESC);

CREATE TABLE images (
  name TEXT PRIMARY KEY,
  bytes BLOB NOT NULL
);

CREATE TABLE practice_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id TEXT NOT NULL,
  user_answer TEXT,
  is_correct INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX idx_logs_question ON practice_logs(question_id);

CREATE TABLE marks (
  question_id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL
);

CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0, help="cap questions (dev builds)")
    # 4 = 带上了一材多题的材料（资料分析的统计表全在这里）。
    parser.add_argument("--seed-version", default="4")
    args = parser.parse_args()

    src = sqlite3.connect(resolve_source_db())
    src.row_factory = sqlite3.Row
    index = asset_index()

    out_path = os.path.join(tempfile.gettempdir(), "openexam_seed_mobile.db")
    if os.path.exists(out_path):
        os.remove(out_path)
    out = sqlite3.connect(out_path)
    out.executescript(SCHEMA)

    papers = {
        row["id"]: row
        for row in src.execute("SELECT id, title, year, question_count FROM papers")
    }

    sql = "SELECT * FROM questions ORDER BY paper_id, order_num"
    if args.limit:
        sql += f" LIMIT {args.limit}"

    used: set[str] = set()
    rows = []
    skipped = 0
    # material_group_id -> (content_html, paper_id)。同一组只存一份。
    materials: dict[str, tuple[str, str]] = {}

    for q in src.execute(sql):
        content_html = fill_blanks(
            rewrite_assets(q["content_html"] or q["content"] or "", used)
        )
        analysis_html = ANALYSIS_TAG.sub(
            r"\1",
            fill_blanks(rewrite_assets(q["analysis_html"] or q["analysis"] or "", used)),
        )

        # 材料。资料分析 2691 题里 2679 题挂着材料, 而且材料主体是统计表图片,
        # 所以这里必须跟着 rewrite_assets 走一遍, 图片才会被收进 images 表 ——
        # 漏了这一步, 题面就只剩一句光秃秃的设问, 根本没法做。
        material_id = (q["material_group_id"] or "").strip()
        material_html = fill_blanks(rewrite_assets(q["material_html"] or "", used))
        if material_id and material_html:
            materials.setdefault(material_id, (material_html, q["paper_id"] or ""))
        else:
            material_id = ""

        try:
            raw_options = json.loads(q["options"] or "[]")
        except json.JSONDecodeError:
            skipped += 1
            continue

        options = []
        for opt in raw_options:
            if not isinstance(opt, dict):
                continue
            html = fill_blanks(
                rewrite_assets(opt.get("content") or opt.get("text") or "", used)
            )
            options.append(
                {
                    "key": (opt.get("key") or "").upper(),
                    "text": plain_text(html),
                    "html": html,
                }
            )

        content = plain_text(content_html)
        answer = (q["answer"] or "").strip().upper()
        if not content or len(options) < 2 or not answer:
            skipped += 1
            continue

        paper = papers.get(q["paper_id"])
        # 材料也算进 has_image —— 资料分析的图全在材料里, 不算的话这些题会被
        # 当成纯文字题。
        blob = f"{content_html}{analysis_html}{material_html}" + "".join(
            o["html"] for o in options
        )
        rows.append(
            (
                q["id"],
                content,
                content_html,
                json.dumps(options, ensure_ascii=False),
                answer,
                q["category"] or "",
                q["sub_category"] or "",
                plain_text(analysis_html),
                analysis_html,
                q["paper_id"] or "",
                paper["title"] if paper else "",
                paper["year"] if paper else 0,
                q["difficulty"] or 2,
                "builtin",
                1 if "oeimg://" in blob else 0,
                q["order_num"] or 0,
                material_id,
                # 答案多于一个字母就按多选算, 不完全信 type 列 ——
                # 上游有 18 道标了 multiple 但答案只有一个字母。
                "multiple"
                if (q["type"] == "multiple" and len(answer) > 1)
                else "single",
            )
        )

    out.executemany(
        "INSERT INTO questions (id, content, content_html, options, answer, category,"
        " sub_category, analysis, analysis_html, paper_id, paper_title, year, difficulty,"
        " source, has_image, order_num, material_id, type)"
        " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        rows,
    )

    # 只留真被题引用到的材料 —— 上面那些 skipped 的题（选项坏了/没答案）
    # 可能是某组里唯一一道，材料留着就是死数据。
    kept = {r[16] for r in rows if r[16]}
    out.executemany(
        "INSERT INTO materials (id, content, content_html, paper_id, source)"
        " VALUES (?,?,?,?,'builtin')",
        [
            (mid, plain_text(html), html, paper_id)
            for mid, (html, paper_id) in materials.items()
            if mid in kept
        ],
    )

    missing = 0
    total_bytes = 0
    for base in sorted(used):
        name = index.get(base)
        if not name:
            missing += 1
            continue
        with open(os.path.join(ASSET_DIR, name), "rb") as fh:
            data = fh.read()
        total_bytes += len(data)
        out.execute("INSERT OR REPLACE INTO images (name, bytes) VALUES (?, ?)", (base, data))

    # 高频词表。只数逻辑填空 —— 别的题型选项是句子, 拆出来的是碎片不是词。
    freq: dict[str, int] = {}
    freq_sample: dict[str, str] = {}
    word_re = re.compile(r"^[\u4e00-\u9fa5]{2,4}$")
    for r in rows:
        if r[6] != "xuanci":
            continue
        for opt in json.loads(r[3]):
            # 多空题的选项形如「疾风骤雨 击落」, 按分隔符拆开;
            # 每段必须整体是 2-4 个汉字, 半个词或带标点的一概不要。
            for piece in re.split(r"[\s、,，/]+", opt.get("text") or ""):
                if word_re.match(piece):
                    freq[piece] = freq.get(piece, 0) + 1
                    freq_sample.setdefault(piece, r[0])
    out.executemany(
        "INSERT INTO word_freq (word, count, sample_question_id) VALUES (?,?,?)",
        [(w, n, freq_sample[w]) for w, n in freq.items()],
    )

    out.execute(
        "INSERT OR REPLACE INTO meta (key, value) VALUES ('seed_version', ?)",
        (args.seed_version,),
    )
    out.commit()
    out.execute("VACUUM")
    out.close()

    os.makedirs(os.path.dirname(OUT_GZ), exist_ok=True)
    with open(out_path, "rb") as fin, gzip.open(OUT_GZ, "wb", compresslevel=9) as fout:
        shutil.copyfileobj(fin, fout)

    print(f"questions : {len(rows)} (skipped {skipped})")
    print(f"word freq : {len(freq)} words, {sum(1 for n in freq.values() if n >= 10)} seen 10+ times")
    print(f"multiple  : {sum(1 for r in rows if r[17] == 'multiple')}")
    print(f"materials : {len(kept)} groups, {sum(1 for r in rows if r[16])} questions attached")
    print(f"with image: {sum(1 for r in rows if r[14])}")
    print(f"images    : {len(used) - missing} embedded, {missing} missing, "
          f"{total_bytes / 1e6:.1f} MB raw")
    print(f"db        : {os.path.getsize(out_path) / 1e6:.1f} MB")
    print(f"gz        : {os.path.getsize(OUT_GZ) / 1e6:.1f} MB -> {OUT_GZ}")


if __name__ == "__main__":
    main()

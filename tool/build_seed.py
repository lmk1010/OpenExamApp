#!/usr/bin/env python3
"""Build the mobile seed database from the OpenExam desktop seed.

Reads ../openexam/data/openexam.seed.db (+ data/question-assets) and writes a
ready-to-open SQLite file with the mobile schema, images embedded as BLOBs, then
gzips it into assets/seed/. The app decompresses it on first launch, so there is
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
OUT_GZ = os.path.join(APP, "assets", "seed", "openexam_seed.db.gz")

ASSET_REF = re.compile(r"openexam-asset://question-assets/([A-Za-z0-9._-]+)")
TAG = re.compile(r"<[^>]+>")


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
  order_num INTEGER DEFAULT 0
);
CREATE INDEX idx_q_cat ON questions(category);
CREATE INDEX idx_q_source ON questions(source);
CREATE INDEX idx_q_paper ON questions(paper_id);

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
    parser.add_argument("--seed-version", default="3")
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

    for q in src.execute(sql):
        content_html = rewrite_assets(q["content_html"] or q["content"] or "", used)
        analysis_html = rewrite_assets(q["analysis_html"] or q["analysis"] or "", used)

        try:
            raw_options = json.loads(q["options"] or "[]")
        except json.JSONDecodeError:
            skipped += 1
            continue

        options = []
        for opt in raw_options:
            if not isinstance(opt, dict):
                continue
            html = rewrite_assets(opt.get("content") or opt.get("text") or "", used)
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
        blob = f"{content_html}{analysis_html}" + "".join(o["html"] for o in options)
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
            )
        )

    out.executemany(
        "INSERT INTO questions (id, content, content_html, options, answer, category,"
        " sub_category, analysis, analysis_html, paper_id, paper_title, year, difficulty,"
        " source, has_image, order_num) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        rows,
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
    print(f"with image: {sum(1 for r in rows if r[14])}")
    print(f"images    : {len(used) - missing} embedded, {missing} missing, "
          f"{total_bytes / 1e6:.1f} MB raw")
    print(f"db        : {os.path.getsize(out_path) / 1e6:.1f} MB")
    print(f"gz        : {os.path.getsize(OUT_GZ) / 1e6:.1f} MB -> {OUT_GZ}")


if __name__ == "__main__":
    main()

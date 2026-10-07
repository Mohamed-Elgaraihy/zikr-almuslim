#!/usr/bin/env python3
"""Rebuild assets/data/azkar.json from the IslamBook azkar pages.

The category list and the order match the public index. Each page is read
in full: heading, wording, repeat count, and the virtue note under the text.
"""

import html
import json
import re
import time
import urllib.request
from pathlib import Path
from urllib.parse import quote, urlsplit, urlunsplit

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "data" / "azkar.json"

# Titles are the buttons on https://www.islambook.com/azkar/ , in that order.
CATEGORIES = [
    ("morning", "أذكار الصباح", "https://www.islambook.com/azkar/1/أذكار-الصباح", True),
    ("evening", "أذكار المساء", "https://www.islambook.com/azkar/2/أذكار-المساء", True),
    ("after-prayer", "أذكار بعد الصلاة", "https://www.islambook.com/azkar/9/أذكار-بعد-السلام-من-الصلاة-المفروضة", False),
    ("tasbih", "تسابيح", "https://www.islambook.com/azkar/3/تسابيح-تسبيح-السبحة-أذكار-عظيمة", False),
    ("sleep", "أذكار النوم", "https://www.islambook.com/azkar/11/أذكار-النوم-والأحلام", False),
    ("waking", "أذكار الاستيقاظ", "https://www.islambook.com/azkar/12/أذكار-الإستيقاظ-من-النوم", False),
    ("prayer", "أذكار الصلاة", "https://www.islambook.com/azkar/22/أذكار-الصلاة", False),
    ("comprehensive", "جوامع الدعاء", "https://www.islambook.com/azkar/20/جوامع-الدعاء", False),
    ("prophetic", "أدعية نبوية", "https://www.islambook.com/azkar/21/أدعية-النبي-صلى-الله-عليه-وسلم", False),
    ("quranic", "الأدعية القرآنية", "https://www.islambook.com/azkar/15/الأدعية-القرآنية", False),
    ("prophets", "أدعية الأنبياء", "https://www.islambook.com/azkar/28/أدعية-الأنبياء-من-القرآن-الكريم", False),
    ("various", "أذكار متفرقة", "https://www.islambook.com/azkar/14/أذكار-متفرقة", False),
    ("adhan", "أذكار الآذان", "https://www.islambook.com/azkar/5/أذكار-عند-سماع-الآذان", False),
    ("mosque", "أذكار المسجد", "https://www.islambook.com/azkar/6/أذكار-المسجد", False),
    ("wudu", "أذكار الوضوء", "https://www.islambook.com/azkar/10/أذكار-الوضوء", False),
    ("home", "أذكار المنزل", "https://www.islambook.com/azkar/4/أذكار-دخول-وخروج-المنزل", False),
    ("toilet", "أذكار الخلاء", "https://www.islambook.com/azkar/7/أذكار-دخول-وخروج-الخلاء", False),
    ("food", "أذكار الطعام", "https://www.islambook.com/azkar/13/أذكار-الطعام-والشراب-والضيف", False),
    ("hajj", "أذكار الحج والعمرة", "https://www.islambook.com/azkar/17/أذكار-الحج-والعمرة", False),
    ("khatm", "دعاء ختم القرآن الكريم", "https://www.islambook.com/azkar/16/دعاء-ختم-القرآن-الكريم", False),
    ("dua-virtue", "فضل الدعاء", "https://www.islambook.com/azkar/18/فضل-الدعاء", False),
    ("dhikr-virtue", "فضل الذكر", "https://www.islambook.com/azkar/19/فضل-الذكر", False),
    ("surah-virtue", "فضل السور", "https://www.islambook.com/azkar/24/فضائل-السور", False),
    ("quran-virtue", "فضل القرآن", "https://www.islambook.com/azkar/23/فضائل-القرآن", False),
    ("names", "أسماء الله الحسنى", "https://www.islambook.com/azkar/25/أسماء-الله-الحسنى", False),
    ("deceased", "أدعية للميّت", "https://www.islambook.com/azkar/27/أدعية-للميت", False),
    ("ruqyah", "الرُّقية الشرعية", "https://www.islambook.com/azkar/26/الرقية-الشرعية-من-القرآن-والسنة", False),
]


def ascii_url(url):
    parts = urlsplit(url)
    return urlunsplit(
        (parts.scheme, parts.netloc, quote(parts.path, safe="/%"), parts.query, "")
    )


def fetch(url):
    request = urllib.request.Request(
        ascii_url(url),
        headers={
            "User-Agent": (
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
            ),
            "Accept-Language": "ar,en;q=0.8",
        },
    )
    last_error = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=40) as response:
                return response.read().decode("utf-8")
        except Exception as error:  # noqa: BLE001 - retry transient network errors
            last_error = error
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def plain(fragment):
    fragment = re.sub(r"(?is)<style[^>]*>.*?</style>", "", fragment)
    fragment = re.sub(r"(?is)<script[^>]*>.*?</script>", "", fragment)
    fragment = re.sub(r"(?i)<br\s*/?>", "\n", fragment)
    fragment = re.sub(r"(?i)</(div|p|li|h[1-6]|tr)>", "\n", fragment)
    fragment = re.sub(r"(?i)<li[^>]*>", "\n", fragment)
    fragment = re.sub(r"<[^>]+>", "", fragment)
    fragment = html.unescape(fragment).replace("\u00a0", " ")
    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in fragment.splitlines()]
    text = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()
    return text


def names_text(block):
    """The beautiful names are buttons: the name is visible, the meaning is on the button."""
    pairs = re.findall(
        r'data-title="(.*?)"[^>]*>\s*<span class="catbutton[^"]*">(.*?)</span>',
        block,
        re.S,
    )
    if not pairs:
        return ""
    lines = []
    for meaning, name in pairs:
        name = plain(name)
        meaning = plain(meaning)
        lines.append(f"{name}\n{meaning}" if meaning else name)
    return "\n\n".join(lines)


def parse_items(page):
    rows = re.split(r'class="row zekr-row', page)[1:]
    items = []
    for row in rows:
        zekr = re.search(
            r'class="zekr zekr-style[^"]*">(.*?)<span class="fa fa-share',
            row,
            re.S,
        )
        if not zekr:
            continue
        block = zekr.group(1)
        heading_match = re.search(
            r'class="subtitle">(.*?)</div>',
            block,
            re.S,
        )
        heading = plain(heading_match.group(1)) if heading_match else ""
        body_html = block
        if heading_match:
            body_html = block[heading_match.end() :]
        text = names_text(body_html) or plain(body_html)
        if not text and heading:
            text = heading
            heading = ""
        if not text:
            continue
        bless_match = re.search(
            r'class="zekrbless-content">(.*?)</span>',
            row,
            re.S,
        )
        virtue = plain(bless_match.group(1)) if bless_match else ""
        count_match = re.search(r'data-count="(\d+)"', row)
        # The site prints 00 on passages that are read, not counted.
        count = int(count_match.group(1)) if count_match else 1
        if count < 1:
            count = 1
        item = {"id": len(items) + 1, "text": text, "count": count}
        if heading:
            item["heading"] = heading
        if virtue:
            item["virtue"] = virtue
        items.append(item)
    return items


def main():
    categories = []
    for category_id, title, url, daily in CATEGORIES:
        page = fetch(url)
        items = parse_items(page)
        if not items:
            raise SystemExit(f"{title} ({url}) parsed to zero items")
        repeats = sum(item["count"] for item in items)
        print(f"{len(items):3} items  {repeats:5} repeats  {title}")
        categories.append(
            {
                "id": category_id,
                "title": title,
                "group": "book",
                "daily": daily,
                "items": items,
            }
        )
        time.sleep(0.25)

    library = {
        "title": "ذكر المسلم",
        "source": "الأبواب ونصوصها وعددها كما هي في أذكار إسلام بوك: https://www.islambook.com/azkar/",
        "groups": [{"id": "book", "title": ""}],
        "categories": categories,
    }
    OUT.write_text(
        json.dumps(library, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    total = sum(len(category["items"]) for category in categories)
    print(f"wrote {OUT} — {len(categories)} categories, {total} items")


if __name__ == "__main__":
    main()

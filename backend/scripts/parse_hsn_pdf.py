"""Regenerate backend/app/data/hsn_codes.json from an official HSN PDF.

Run this whenever GST Council publishes a revised HSN code list.

Usage:
    pip install pdfplumber
    python scripts/parse_hsn_pdf.py /path/to/new-hsn-notification.pdf

This overwrites app/data/hsn_codes.json. Nothing else in the app needs to
change — the offline provider reloads this file at next process start.
"""

import json
import re
import sys
from pathlib import Path

import pdfplumber

OUTPUT_PATH = Path(__file__).resolve().parent.parent / "app" / "data" / "hsn_codes.json"

_SL_PREFIX_RE = re.compile(r"^\d+\s+")
_CODE_LINE_RE = re.compile(r"^(\d{2,4}(?:[\s.]\d{2,4}){0,3})\s+(.*\S)\s*$")


def extract_text(pdf_path: str) -> str:
    with pdfplumber.open(pdf_path) as pdf:
        return "\n".join(page.extract_text() or "" for page in pdf.pages)


def parse_entries(text: str) -> dict[str, str]:
    entries: dict[str, str] = {}

    for raw_line in text.split("\n"):
        line = raw_line.strip()
        if not line or line.startswith("SL NO") or line.startswith("HSN CODE"):
            continue

        line = _SL_PREFIX_RE.sub("", line, count=1)
        match = _CODE_LINE_RE.match(line)
        if not match:
            continue

        raw_code, description = match.groups()
        digits = re.sub(r"\D", "", raw_code)

        if len(digits) < 4 or len(digits) > 8 or len(digits) % 2 != 0:
            continue  # HSN codes are 4/6/8 digits; 2-digit chapters live in hsn_chapters.json

        description = description.strip().rstrip(";").strip()
        if len(description) < 3 or description.isdigit():
            continue  # drop junk rows (stray numbers, empty headers)

        entries.setdefault(digits, description)  # first occurrence wins

    return entries


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python parse_hsn_pdf.py <path-to-pdf>")
        sys.exit(1)

    text = extract_text(sys.argv[1])
    entries = parse_entries(text)

    OUTPUT_PATH.write_text(json.dumps(entries, indent=1, sort_keys=True), encoding="utf-8")
    print(f"Wrote {len(entries)} codes to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

import io
import re
from typing import Dict, List, Optional
import fitz  # PyMuPDF
import numpy as np
from fastapi import FastAPI, UploadFile, File, HTTPException, WebSocket
from PIL import Image

app = FastAPI(title="Dhandas Scan OCR Engine")

_ocr_engine = None


def get_ocr_engine():
    global _ocr_engine
    if _ocr_engine is None:
        from rapidocr_onnxruntime import RapidOCR
        _ocr_engine = RapidOCR()
    return _ocr_engine


def run_ocr(image: Image.Image) -> str:
    engine = get_ocr_engine()
    arr = np.array(image.convert("RGB"))
    result, _ = engine(arr)
    if not result:
        return ""
    return "\n".join([r[1] for r in result if r[1].strip()])


def run_ocr_boxes(image: Image.Image) -> List[Dict]:
    """Run OCR and keep each detected box's text + position so table rows/columns
    can be reconstructed. Plain run_ocr() loses this and is why image / scanned
    invoices could not extract line items reliably."""
    engine = get_ocr_engine()
    arr = np.array(image.convert("RGB"))
    result, _ = engine(arr)
    boxes = []
    if not result:
        return boxes
    for box, text, _conf in result:
        text = str(text).strip()
        if not text:
            continue
        xs = [p[0] for p in box]
        ys = [p[1] for p in box]
        boxes.append({
            "text": text,
            "x": min(xs),
            "y": (min(ys) + max(ys)) / 2.0,
            "h": max(ys) - min(ys) or 10.0,
        })
    return boxes


def group_boxes_into_rows(boxes: List[Dict]) -> List[List[Dict]]:
    boxes = sorted(boxes, key=lambda b: b["y"])
    rows: List[List[Dict]] = []
    for b in boxes:
        placed = False
        for row in rows:
            ref_y = sum(r["y"] for r in row) / len(row)
            avg_h = sum(r["h"] for r in row) / len(row)
            if abs(b["y"] - ref_y) < max(avg_h, 10) * 0.6:
                row.append(b)
                placed = True
                break
        if not placed:
            rows.append([b])
    for row in rows:
        row.sort(key=lambda b: b["x"])
    rows.sort(key=lambda row: sum(b["y"] for b in row) / len(row))
    return rows


def extract_items_from_ocr_rows(rows: List[List[Dict]]) -> List[Dict]:
    """Reconstruct a line-item table from OCR'd word/line boxes. This is the
    fallback used for scanned PDFs and photographed/image invoices, where
    there is no vector table and text has no pipe/column separators."""
    header_idx = -1
    col_map: Dict[str, int] = {}
    header_kw = ["item", "description", "particular", "hsn", "qty", "quantity",
                 "rate", "price", "unit", "gst", "amount"]

    for i, row in enumerate(rows):
        texts = [c["text"].lower() for c in row]
        hits = sum(1 for t in texts for k in header_kw if k in t)
        if hits >= 2 and len(row) >= 3:
            header_idx = i
            for idx, t in enumerate(texts):
                if "name" not in col_map and any(k in t for k in ["item", "description", "particular"]):
                    col_map["name"] = idx
                elif "hsn" not in col_map and "hsn" in t:
                    col_map["hsn"] = idx
                elif "qty" not in col_map and ("qty" in t or "quantity" in t):
                    col_map["qty"] = idx
                elif "unit" not in col_map and "unit" in t:
                    col_map["unit"] = idx
                elif "rate" not in col_map and ("rate" in t or "price" in t):
                    col_map["rate"] = idx
                elif "tax" not in col_map and ("gst" in t or "%" in t or "tax" in t):
                    col_map["tax"] = idx
            break

    if header_idx == -1 or "name" not in col_map:
        return []

    stop_kw = ["total", "taxable", "cgst", "sgst", "subtotal", "amount in words", "grand total"]
    items = []
    for row in rows[header_idx + 1:]:
        texts = [c["text"] for c in row]
        joined_low = " ".join(texts).lower()
        if any(k in joined_low for k in stop_kw):
            break
        if len(texts) < 2:
            continue

        def col(key: str, default: str = "") -> str:
            idx = col_map.get(key)
            return texts[idx] if idx is not None and idx < len(texts) else default

        name = col("name")
        if not name or name.isdigit() or len(name) < 2:
            alpha_cells = [t for t in texts if not t.replace(".", "").replace(",", "").isdigit() and len(t) > 2]
            name = max(alpha_cells, key=len) if alpha_cells else ""
        if not name or len(name) < 2 or name.isdigit():
            continue

        hsn = col("hsn")
        if hsn and not re.match(r"^\d{4,8}$", hsn):
            hsn = ""
        if not hsn:
            for t in texts:
                if re.match(r"^\d{4,8}$", t):
                    hsn = t
                    break

        qty = _clean_num(col("qty", "1")) or 1.0
        unit = col("unit", "PCS").upper()
        rate = _clean_num(col("rate", "0"))

        tax = 18.0
        t_m = re.findall(r"(\d{1,2})\s*%", col("tax", ""))
        if t_m:
            tax = float(t_m[0])

        items.append({
            "name": name.strip(),
            "hsn": hsn,
            "qty": qty if qty > 0 else 1.0,
            "unit": unit if len(unit) <= 5 else "PCS",
            "rate": rate,
            "taxRatePercent": tax,
        })
    return items


def _clean_num(val_str: str) -> float:
    try:
        cleaned = re.sub(r"[^\d.]", "", val_str)
        return float(cleaned) if cleaned else 0.0
    except Exception:
        return 0.0


GSTIN_RE = re.compile(r"\b\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]\b", re.I)
DATE_RE = re.compile(r"\b(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\b")

# Matches a line-item row that is on a SINGLE line with space-separated
# columns, e.g. "1  LED Panel Light 18W  94054090  25  PCS  420.00  10,500.00  18%".
# This is the common shape for real (digital-text) PDF invoices that have no
# visible ruling lines, so fitz.find_tables() can't detect a table and the
# old pipe-only fallback never matched them either.
ITEM_LINE_RE = re.compile(
    r"^\s*\d{0,3}\.?\s+"
    r"(?P<name>[A-Za-z][A-Za-z0-9\s\-&/().]{1,60}?)\s+"
    r"(?:(?P<hsn>\d{4,8})\s+)?"
    r"(?P<qty>\d+(?:\.\d+)?)\s+"
    r"(?P<unit>[A-Za-z]{2,6})\s+"
    r"(?P<rate>[\d,]+(?:\.\d{1,2})?)\s+"
    r"(?:(?P<taxable>[\d,]+(?:\.\d{1,2})?)\s+)?"
    r"(?P<gst>\d{1,2})\s*%\s*$"
)


def extract_items_from_text_lines(lines: List[str]) -> List[Dict]:
    items = []
    for l in lines:
        m = ITEM_LINE_RE.match(l)
        if not m:
            continue
        name = m.group("name").strip()
        if not name or name.isdigit() or len(name) < 2:
            continue
        unit = m.group("unit").upper()
        items.append({
            "name": name,
            "hsn": m.group("hsn") or "",
            "qty": _clean_num(m.group("qty")) or 1.0,
            "unit": unit if len(unit) <= 5 else "PCS",
            "rate": _clean_num(m.group("rate")),
            "taxRatePercent": float(m.group("gst")),
        })
    return items


def extract_tables_from_pdf(doc: fitz.Document) -> List[Dict]:
    items = []
    header_keywords = {"item", "description", "particulars", "hsn", "qty", "rate", "price", "unit"}

    for page in doc:
        try:
            tabs = page.find_tables()
            if not tabs or not tabs.tables:
                continue
            for tab in tabs.tables:
                extracted = tab.extract()
                if not extracted or len(extracted) < 2:
                    continue

                headers = [str(c).strip().lower() if c else "" for c in extracted[0]]

                name_idx = -1
                hsn_idx = -1
                qty_idx = -1
                unit_idx = -1
                rate_idx = -1
                gst_idx = -1

                for idx, h in enumerate(headers):
                    if any(k in h for k in ["item", "description", "particulars"]):
                        name_idx = idx
                    elif "hsn" in h:
                        hsn_idx = idx
                    elif "qty" in h:
                        qty_idx = idx
                    elif "unit" in h:
                        unit_idx = idx
                    elif "rate" in h or "price" in h:
                        rate_idx = idx
                    elif "gst" in h or "%" in h:
                        gst_idx = idx

                for row in extracted[1:]:
                    if not row or len(row) < 3:
                        continue
                    row_str = " ".join([str(c).lower() for c in row if c])
                    if any(k in row_str for k in ["total", "taxable", "cgst", "sgst", "subtotal"]):
                        continue

                    name = str(row[name_idx]).strip() if name_idx != -1 else ""
                    if not name or name.isdigit() or any(k in name.lower() for k in header_keywords):
                        if len(row) > 1 and str(row[1]).strip() and not str(row[1]).strip().isdigit():
                            name = str(row[1]).strip()

                    if not name or len(name) < 2:
                        continue

                    hsn = str(row[hsn_idx]).strip() if hsn_idx != -1 and row[hsn_idx] else ""
                    if not hsn:
                        for cell in row:
                            if cell and re.match(r"^\d{4,8}$", str(cell).strip()):
                                hsn = str(cell).strip()
                                break

                    qty = _clean_num(str(row[qty_idx])) if qty_idx != -1 and row[qty_idx] else 1.0
                    unit = str(row[unit_idx]).strip().upper() if unit_idx != -1 and row[unit_idx] else "PCS"
                    rate = _clean_num(str(row[rate_idx])) if rate_idx != -1 and row[rate_idx] else 0.0

                    tax = 18.0
                    if gst_idx != -1 and row[gst_idx]:
                        t_m = re.findall(r"(\d{1,2})\s*%", str(row[gst_idx]))
                        if t_m:
                            tax = float(t_m[0])

                    items.append({
                        "name": name,
                        "hsn": hsn,
                        "qty": qty if qty > 0 else 1.0,
                        "unit": unit if len(unit) <= 5 else "PCS",
                        "rate": rate,
                        "taxRatePercent": tax
                    })
        except Exception as e:
            print(f"Table extract error: {e}")
    return items


def parse_invoice_text(raw_text: str, pre_extracted_items: Optional[List[Dict]] = None) -> Dict:
    lines = [l.strip() for l in raw_text.splitlines() if l.strip()]
    full = "\n".join(lines)

    # 1. Invoice Number Extraction
    inv_no = ""
    inv_m = re.search(
        r"(?:Invoice\s*No\.?|Inv\s*No\.?|Bill\s*No\.?|Invoice\s*#)[\s.:#|]*\n?[\s|]*([A-Za-z0-9/\-]+)",
        full,
        re.IGNORECASE,
    )
    if inv_m and inv_m.group(1).lower() not in ("date", "gstin", "invoice"):
        inv_no = inv_m.group(1).strip()
    else:
        m2 = re.search(r"\b([A-Z]{2,5}[/-]\d{2}[/-]\d+|\b[A-Z]{2,5}/\d{2}-\d{2}/\d+)\b", full)
        if m2:
            inv_no = m2.group(1).strip()

    # 2. Date
    dates = DATE_RE.findall(full)
    invoice_date = dates[0].replace("/", "-") if dates else ""

    # 3. GSTINs
    gstins = GSTIN_RE.findall(full)
    party_gstin = gstins[1].upper() if len(gstins) > 1 else (gstins[0].upper() if gstins else "")

    # 4. Party Name
    party_name = ""
    for idx, l in enumerate(lines):
        if any(w in l.lower() for w in ["bill to", "buyer", "customer"]):
            if ":" in l:
                cand = l.split(":", 1)[1].strip()
                if cand:
                    party_name = cand
                    break
            if idx + 1 < len(lines):
                cand = lines[idx + 1].strip().lstrip("|").strip()
                if not any(cand.lower().startswith(x) for x in ["site:", "address:", "gstin:"]):
                    party_name = cand
                    break

    if not party_name and lines:
        for l in lines[:6]:
            cand = l.lstrip("|").strip()
            if not any(w in cand.lower() for w in ["tax", "invoice", "gstin", "date"]):
                party_name = cand
                break

    party_name = re.sub(r"^(?:bill\s*to|buyer|customer)[\s.:]*", "", party_name, flags=re.I).strip()
    # Two-column headers (e.g. "Bill To ... | Due Date ...") put unrelated
    # text on the same line separated by a wide gap; cut it off there.
    party_name = re.split(r"\s{2,}", party_name)[0].strip()

    # 5. Sundries (Discount & Freight)
    sundries: List[Dict] = []
    for l in lines:
        low = l.lower()
        if "discount" in low:
            nums = re.findall(r"[\d,]+(?:\.\d{2})?", l)
            if nums:
                amt = _clean_num(nums[-1])
                if amt > 0:
                    sundries.append({"name": "Discount", "amount": amt, "isNegative": True})
        elif "freight" in low or "transport" in low:
            nums = re.findall(r"[\d,]+(?:\.\d{2})?", l)
            if nums:
                amt = _clean_num(nums[-1])
                if amt > 0:
                    sundries.append({"name": "Freight & Forwarding Charges", "amount": amt, "isNegative": False})

    # 6. Items Resolution
    items = pre_extracted_items or []

    if not items:
        items = extract_items_from_text_lines(lines)

    if not items:
        pipe_cells = []
        summary_bottom = ["taxable value", "gross taxable", "net taxable", "grand total", "total amount", "amount in words"]

        for l in lines:
            low = l.lower()
            if any(tok in low for tok in summary_bottom):
                break
            cleaned = l.strip()
            if cleaned.startswith("|") or cleaned.isdigit():
                val = cleaned.lstrip("|").strip()
                if val and not any(hdr in val.lower() for hdr in ["item description", "particulars", "hsn/sac", "unit", "rate"]):
                    pipe_cells.append(val)

        k = 0
        while k < len(pipe_cells):
            if pipe_cells[k].isdigit() and int(pipe_cells[k]) < 100:
                if k + 5 < len(pipe_cells):
                    name = pipe_cells[k + 1]
                    hsn = pipe_cells[k + 2] if re.match(r"^\d{4,8}$", pipe_cells[k + 2]) else ""
                    offset = 0 if hsn else -1

                    qty = _clean_num(pipe_cells[k + 3 + offset]) or 1.0
                    unit = pipe_cells[k + 4 + offset].upper()
                    rate = _clean_num(pipe_cells[k + 5 + offset])

                    tax = 18.0
                    for probe in range(k + 5 + offset, min(k + 9 + offset, len(pipe_cells))):
                        t_m = re.findall(r"(\d{1,2})\s*%", pipe_cells[probe])
                        if t_m:
                            tax = float(t_m[0])
                            break

                    if len(name) > 1 and not name.isdigit():
                        items.append({
                            "name": name,
                            "hsn": hsn,
                            "qty": qty,
                            "unit": unit if len(unit) <= 5 else "PCS",
                            "rate": rate,
                            "taxRatePercent": tax
                        })
                    k += (7 + offset)
                    continue
            k += 1

    return {
        "voucherType": "Sales",
        "partyName": party_name,
        "partyGstin": party_gstin,
        "invoiceNo": inv_no,
        "invoiceDate": invoice_date,
        "items": items,
        "sundries": sundries,
        "totalAmount": 0.0,
        "confidence": 0.95 if items else 0.4,
        "rawText": raw_text,
    }


@app.post("/scan")
async def scan(file: UploadFile = File(...)) -> Dict:
    data = await file.read()
    if not data:
        raise HTTPException(400, "Empty file")

    filename = (file.filename or "invoice.pdf").lower()
    pre_extracted_items: List[Dict] = []
    ocr_texts: List[str] = []

    try:
        if filename.endswith(".pdf") or file.content_type == "application/pdf":
            doc = fitz.open(stream=data, filetype="pdf")
            pre_extracted_items = extract_tables_from_pdf(doc)
            raw_text = "\n".join([page.get_text("text") for page in doc]).strip()

            # A scanned/photographed PDF has little to no extractable text and
            # no vector tables (find_tables needs real text). Previously this
            # meant such files silently returned zero items even though the
            # digital-PDF path worked fine - render each page and OCR it.
            needs_ocr_fallback = (not pre_extracted_items) and len(raw_text) < 40
            if needs_ocr_fallback:
                ocr_rows: List[List[Dict]] = []
                page_limit = min(len(doc), 15)  # keep it scalable/bounded
                for page in doc[:page_limit]:
                    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
                    img = Image.open(io.BytesIO(pix.tobytes("png")))
                    boxes = run_ocr_boxes(img)
                    ocr_texts.append("\n".join(b["text"] for b in boxes))
                    ocr_rows.extend(group_boxes_into_rows(boxes))
                if ocr_rows:
                    pre_extracted_items = extract_items_from_ocr_rows(ocr_rows)
                if not raw_text.strip():
                    raw_text = "\n".join(ocr_texts).strip()
            doc.close()
        else:
            img = Image.open(io.BytesIO(data))
            boxes = run_ocr_boxes(img)
            raw_text = "\n".join(b["text"] for b in boxes)
            rows = group_boxes_into_rows(boxes)
            pre_extracted_items = extract_items_from_ocr_rows(rows)
    except Exception as e:
        raise HTTPException(422, f"Could not read document: {e}")

    if not raw_text.strip():
        raise HTTPException(422, "No readable text found.")

    res = parse_invoice_text(raw_text, pre_extracted_items)
    print(f"DEBUG: Found {len(res['items'])} items: {[it['name'] for it in res['items']]}")
    return res


@app.websocket("/ws/company/{company_id}")
async def websocket_endpoint(websocket: WebSocket, company_id: str):
    await websocket.accept()
    while True:
        try:
            await websocket.receive_text()
        except Exception:
            break


@app.get("/health")
def health():
    return {"status": "ok"}
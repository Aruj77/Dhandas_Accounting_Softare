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


def _clean_num(val_str: str) -> float:
    try:
        cleaned = re.sub(r"[^\d.]", "", val_str)
        return float(cleaned) if cleaned else 0.0
    except Exception:
        return 0.0


GSTIN_RE = re.compile(r"\b\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]\b", re.I)
DATE_RE = re.compile(r"\b(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\b")


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
    pre_extracted_items = []

    try:
        if filename.endswith(".pdf") or file.content_type == "application/pdf":
            doc = fitz.open(stream=data, filetype="pdf")
            pre_extracted_items = extract_tables_from_pdf(doc)
            raw_text = "\n".join([page.get_text("text") for page in doc]).strip()
            doc.close()
        else:
            img = Image.open(io.BytesIO(data))
            raw_text = run_ocr(img)
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
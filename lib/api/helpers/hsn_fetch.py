import json
import re
import pdfplumber


def extract_hsn_dict(pdf_path):
    hsn_dict = {}
    hsn_pattern = re.compile(r"^\b(\d{4}(?:[\s.]\d{2,4})*(?:[\s.]\d{2})*)\b")

    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)

        for page_num, page in enumerate(pdf.pages, start=1):
            # Extract structured table rows
            tables = page.extract_tables()

            for table in tables:
                for row in table:
                    if not row or len(row) < 3:
                        continue

                    # Filter out header rows
                    col0 = str(row[0] or "").strip()
                    col1 = str(row[1] or "").strip()
                    col2 = str(row[2] or "").strip()

                    if "SL" in col0.upper() or "HS" in col1.upper():
                        continue

                    code = None
                    desc = None

                    # Case A: HS Code is in the designated HS Code column (col1)
                    if col1 and any(char.isdigit() for char in col1):
                        code = col1.strip()
                        desc = col2.strip()

                    # Case B: HS Code is embedded inside the text or lines got shifted
                    else:
                        match = hsn_pattern.search(col1 or col2)
                        if match:
                            raw_matched = match.group(1).strip()
                            code = raw_matched
                            desc = col2.replace(raw_matched, "").strip(" -:;")

                    if code and desc:
                        # Remove dots from the HSN code (e.g., 1524.25 -> 152425)
                        clean_code = code.replace(".", "").strip()

                        # Optional: uncomment the line below if you also want to remove spaces (e.g., "0101 21 00" -> "01012100")
                        # clean_code = clean_code.replace(" ", "")

                        hsn_dict[clean_code] = desc

            # Progress log
            print(f"Parsed page {page_num} of {total_pages}")

    return hsn_dict


if __name__ == "__main__":
    pdf_path = "./HSN-Codes-for-GST-Enrolment.pdf"
    output_path = "hsn.json"

    result = extract_hsn_dict(pdf_path)

    # Save to hsn.json
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=4, ensure_ascii=False)

    print(f"\nDone! Successfully extracted {len(result)} HSN codes to {output_path}")
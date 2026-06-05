"""
Always-on OCR service.

Loads the EasyOCR reader ONCE at startup and keeps it warm, so each request
skips the slow model-loading step. The Node backend POSTs a file path here
instead of spawning a fresh Python process every upload.

Same OCR logic as the CLI (imports run_ocr from easyocr_reader) — so results
are identical, just faster. If this service is down, Node falls back to the
old spawn() path automatically.

Run:  python ocr_server.py   (listens on 127.0.0.1:5001)
"""
import os
import sys

# Make sure easyocr_reader.py (same folder) is importable regardless of cwd
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, request, jsonify
from easyocr_reader import run_ocr  # loads the EasyOCR model ONCE on import

app = Flask(__name__)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/ocr")
def ocr():
    data = request.get_json(force=True, silent=True) or {}
    path = data.get("path")
    if not path:
        return jsonify({"error": "missing 'path'"}), 400
    if not os.path.exists(path):
        return jsonify({"error": f"file not found: {path}"}), 400
    try:
        return jsonify(run_ocr(path))
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("OCR_PORT", "5001"))
    # threaded=False → one OCR at a time inside the service (protects memory)
    app.run(host="127.0.0.1", port=port, threaded=False)

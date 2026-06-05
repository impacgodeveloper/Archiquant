const { spawn } = require("child_process");
const path = require("path");
const http = require("http");

// Always-on OCR service (keeps the EasyOCR model warm → fast). If it's not
// running, we fall back to spawning the Python script (slower but always works).
const OCR_URL = process.env.OCR_SERVICE_URL || "http://127.0.0.1:5001/ocr";

// ── Run OCR jobs ONE AT A TIME ──────────────────────────────────────────────
// Serialize so concurrent uploads never run multiple heavy OCRs together
// (which would exhaust VPS memory). Uploads all succeed — just one by one.
let _queue = Promise.resolve();
function runOCR(imagePath) {
  const job = _queue.then(() =>
    _viaService(imagePath).catch((e) => {
      console.warn("OCR service unavailable, falling back to spawn:", e.message);
      return _runOCROnce(imagePath);
    })
  );
  _queue = job.catch(() => {}); // keep the chain alive even if a job fails
  return job;
}

// Fast path — call the warm OCR service over HTTP
function _viaService(imagePath) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ path: path.resolve(imagePath) });
    const u = new URL(OCR_URL);
    const req = http.request(
      {
        hostname: u.hostname,
        port: u.port || 80,
        path: u.pathname,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
        },
        timeout: 180000,
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          if (res.statusCode !== 200) {
            return reject(new Error("OCR service status " + res.statusCode + ": " + data));
          }
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error("Bad JSON from OCR service"));
          }
        });
      }
    );
    req.on("error", reject);
    req.on("timeout", () => req.destroy(new Error("OCR service timeout")));
    req.write(body);
    req.end();
  });
}

// Fallback path — spawn the Python script (original behaviour)
function _runOCROnce(imagePath) {
  return new Promise((resolve, reject) => {
    
    // Ensure the path is absolute (Fixes frontend upload path issues)
    const absoluteImagePath = path.resolve(imagePath);
    
    const script = path.join(__dirname, "../python/easyocr_reader.py");

  const py = spawn(
  process.env.PYTHON_PATH || "python3",
  [script, absoluteImagePath]
);
    let output = "";
    let error = "";

    py.stdout.on("data", (data) => {
      // Collecting output chunks
      output += data.toString();
    });

    py.stderr.on("data", (data) => {
      // Collecting error chunks (Mac often puts warnings here)
      error += data.toString();
    });

    py.on("error", (err) => {
      console.error("SPAWN ERROR:", err);
      reject(err);
    });

    py.on("close", (code) => {
      console.log("PYTHON EXIT CODE:", code);

      if (code !== 0) {
        console.error("PYTHON STDERR:", error);
        return reject(error || "Python process failed");
      }

      try {
        // Fix for Mac: Find the first '{' and last '}' to ignore PyTorch terminal warnings
        const jsonStartIndex = output.indexOf("{");
        const jsonEndIndex = output.lastIndexOf("}");

        if (jsonStartIndex !== -1 && jsonEndIndex !== -1) {
          const cleanJsonString = output.substring(jsonStartIndex, jsonEndIndex + 1);
          resolve(JSON.parse(cleanJsonString));
        } else {
          console.error("RAW PYTHON OUTPUT:", output);
          reject("No valid JSON found in Python output.");
        }
      } catch (e) {
        console.error("JSON PARSE ERROR. RAW OUTPUT WAS:", output);
        reject("Invalid JSON from Python");
      }
    });

  });
}

module.exports = { runOCR };
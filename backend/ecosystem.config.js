// PM2 process definitions. Deploy:  pm2 start ecosystem.config.js && pm2 save
// Gives both the API and the Python OCR sidecar auto-restart, a memory ceiling,
// and timestamped logs (rotate with `pm2 install pm2-logrotate`).
module.exports = {
  apps: [
    {
      name: "archiquant-api",
      script: "server.js",
      cwd: __dirname,
      instances: 1,            // bump to "max" once the app is verified stateless
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: "512M",
      env: { NODE_ENV: "production" },
      time: true,
    },
    {
      name: "archiquant-ocr",
      script: "ocr_server.py",
      cwd: `${__dirname}/python`,
      interpreter: process.env.PYTHON_PATH || "python3",
      autorestart: true,
      max_memory_restart: "1500M", // EasyOCR/torch are memory-heavy
      time: true,
    },
    // Async OCR worker — only needed when OCR_ASYNC=true (requires Redis).
    // Scale by raising `instances`. Start with: pm2 start ecosystem.config.js --only archiquant-ocr-worker
    {
      name: "archiquant-ocr-worker",
      script: "workers/ocrWorker.js",
      cwd: __dirname,
      instances: 2,
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: "768M",
      env: { NODE_ENV: "production" },
      time: true,
    },
  ],
};

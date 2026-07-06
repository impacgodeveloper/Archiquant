// OCR worker (consumer side). Run as a separate process, scaled horizontally:
//   OCR_ASYNC=true REDIS_URL=redis://... node workers/ocrWorker.js
// Or under PM2 (see ecosystem.config.js — archiquant-ocr-worker).
//
// Pulls jobs off the "ocr" queue, runs EasyOCR, and writes the result back to
// floor_plans. BullMQ handles retries/backoff; the final-failure handler marks
// the row ocr_status = "failed" so the client polling /plan sees the outcome.

require("dotenv").config();
const pino = require("pino");
const { Worker } = require("bullmq");
const IORedis = require("ioredis");
const { runOCR } = require("../services/easyocrService");
const supabase = require("../config/supabase");
const { QUEUE_NAME, REDIS_URL } = require("../services/ocrQueue");

const logger = pino({ level: process.env.LOG_LEVEL || "info" });
const concurrency = parseInt(process.env.OCR_WORKER_CONCURRENCY, 10) || 2;
const connection = new IORedis(REDIS_URL, { maxRetriesPerRequest: null });

const worker = new Worker(
  QUEUE_NAME,
  async (job) => {
    const { floor_plan_id, file_path } = job.data;
    logger.info({ jobId: job.id, floor_plan_id }, "OCR job start");
    const result = await runOCR(file_path);
    const { error } = await supabase
      .from("floor_plans")
      .update({ ocr_status: "done", raw_ocr_data: result })
      .eq("id", floor_plan_id);
    if (error) throw new Error(`DB update failed: ${error.message}`);
    logger.info({ jobId: job.id, floor_plan_id }, "OCR job done");
    return { floor_plan_id };
  },
  { connection, concurrency }
);

// Final failure (after all retries) → mark the plan failed so the UI can react.
worker.on("failed", async (job, err) => {
  logger.error({ jobId: job?.id, err: err.message }, "OCR job failed");
  if (job && job.attemptsMade >= (job.opts.attempts || 1)) {
    await supabase.from("floor_plans")
      .update({ ocr_status: "failed" })
      .eq("id", job.data.floor_plan_id)
      .then(() => {}, () => {});
  }
});

worker.on("error", (err) => logger.error({ err: err.message }, "OCR worker error"));

async function shutdown() { await worker.close(); process.exit(0); }
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

logger.info(`OCR worker started (concurrency=${concurrency})`);

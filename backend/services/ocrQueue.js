// OCR job queue (producer side).
//
// Enabled only when OCR_ASYNC=true AND REDIS_URL is set. When disabled, the
// API keeps doing OCR synchronously inside the upload request (current
// behavior) — so this module is purely additive and breaks nothing until you
// flip the flag and run the worker (workers/ocrWorker.js).
//
// Architecture:
//   POST /floor-plans  ──enqueue──▶  Redis (BullMQ "ocr" queue)
//                                        │
//                          workers/ocrWorker.js (N processes)
//                                        │ runOCR(file) → update floor_plans
//                                        ▼
//   client polls GET /projects/:id/plan until ocr_status = done|failed
//
// Retries: 3 attempts, exponential backoff. On final failure the worker marks
// the floor_plan ocr_status = "failed" so the UI can surface it.

const OCR_ASYNC = process.env.OCR_ASYNC === "true";
const REDIS_URL = process.env.REDIS_URL || "redis://127.0.0.1:6379";
const QUEUE_NAME = "ocr";

let _queue = null;

function isAsyncEnabled() {
  return OCR_ASYNC;
}

// Lazily construct the queue (and its Redis connection) only when async is on.
function getQueue() {
  if (!OCR_ASYNC) return null;
  if (_queue) return _queue;
  const { Queue } = require("bullmq");
  const IORedis = require("ioredis");
  const connection = new IORedis(REDIS_URL, { maxRetriesPerRequest: null });
  _queue = new Queue(QUEUE_NAME, { connection });
  return _queue;
}

// Enqueue an OCR job. Returns the BullMQ job id.
async function enqueueOcr({ floor_plan_id, file_path, company_id, project_id }) {
  const queue = getQueue();
  if (!queue) throw new Error("OCR async queue is disabled");
  const job = await queue.add(
    "process",
    { floor_plan_id, file_path, company_id, project_id },
    {
      attempts: 3,
      backoff: { type: "exponential", delay: 5000 },
      removeOnComplete: 1000,
      removeOnFail: 5000,
    }
  );
  return job.id;
}

module.exports = { isAsyncEnabled, enqueueOcr, getQueue, QUEUE_NAME, REDIS_URL };

require("dotenv").config();

// Node < 22 has no global WebSocket; @supabase/realtime-js requires one at
// construction. We don't use realtime, but createClient builds it anyway —
// polyfill with `ws` so the client constructs on Node 20.
if (typeof globalThis.WebSocket === "undefined") {
  try {
    globalThis.WebSocket = require("ws");
  } catch (_) {/* if ws is missing, createClient will surface its own error */}
}

const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY,
  { realtime: { disabled: true } }
);

module.exports = supabase;
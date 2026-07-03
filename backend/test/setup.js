// Jest global setup — runs before each test file. Provides dummy env so the
// server boots without real secrets (the real Supabase client is mocked).
process.env.NODE_ENV           = "test";
process.env.JWT_SECRET         = "test-access-secret";
process.env.JWT_REFRESH_SECRET = "test-refresh-secret";
process.env.SUPABASE_URL         = "http://localhost";
process.env.SUPABASE_SERVICE_KEY = "test-service-key";

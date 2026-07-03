module.exports = {
  testEnvironment: "node",
  setupFiles: ["<rootDir>/test/setup.js"],
  testMatch: ["**/test/**/*.test.js"],
  // node_modules of the real app are large; keep coverage focused.
  collectCoverageFrom: ["server.js", "utils/**/*.js"],
};

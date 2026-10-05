import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globalSetup: ["./test/global-setup.ts"],
    // Every test file shares one Postgres database and truncates it in
    // beforeEach, so files must not run concurrently.
    fileParallelism: false,
  },
});

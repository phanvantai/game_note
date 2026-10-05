export interface Config {
  port: number;
  databaseUrl: string;
  firebaseProjectId: string;
  /** Public origin used to build avatar URLs, e.g. https://gamenote-api.example.com */
  publicBaseUrl: string;
  avatarDir: string;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const databaseUrl = env.DATABASE_URL;
  if (!databaseUrl) throw new Error("DATABASE_URL is required");
  return {
    port: Number(env.PORT ?? 8080),
    databaseUrl,
    firebaseProjectId: env.FIREBASE_PROJECT_ID ?? "gamenoteapp",
    publicBaseUrl: (env.PUBLIC_BASE_URL ?? "http://localhost:8080").replace(/\/$/, ""),
    avatarDir: env.AVATAR_DIR ?? "./data/avatars",
  };
}

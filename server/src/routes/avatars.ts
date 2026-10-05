import { createReadStream } from "node:fs";
import { mkdir, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import type { FastifyPluginAsync } from "fastify";
import type { AppDeps } from "../app.js";
import { notFound, validation } from "../errors.js";
import { caller } from "../http.js";
import { userJson, type UserRow } from "../rows.js";

const EXTENSIONS: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/gif": "gif",
};
const SAFE_FILE = /^[A-Za-z0-9_-]+\.(jpg|png|webp|heic|gif)$/;

export function avatarRoutes({ db, config }: AppDeps): FastifyPluginAsync {
  const prefix = `${config.publicBaseUrl}/avatars/`;

  /** Deletes an avatar file this server hosts; other URLs are left alone. */
  const removeHosted = async (photoUrl: string | null) => {
    if (!photoUrl?.startsWith(prefix)) return;
    const file = photoUrl.slice(prefix.length);
    if (SAFE_FILE.test(file)) await rm(path.join(config.avatarDir, file), { force: true });
  };

  const setPhoto = async (uid: string, photoUrl: string | null) => {
    const { rows } = await db.query<UserRow>(
      "UPDATE users SET photo_url = $2, updated_at = now() WHERE id = $1 RETURNING *",
      [uid, photoUrl],
    );
    if (!rows[0]) throw notFound("User");
    return rows[0];
  };

  return async (app) => {
    app.put("/v1/me/avatar", async (req) => {
      const { uid } = caller(req);
      const file = await req.file();
      if (!file) throw validation("Missing file");
      const ext = EXTENSIONS[file.mimetype];
      if (!ext) throw validation(`Unsupported image type ${file.mimetype}`);
      const bytes = await file.toBuffer();

      const { rows } = await db.query<UserRow>("SELECT * FROM users WHERE id = $1", [uid]);
      if (!rows[0]) throw notFound("User");

      await mkdir(config.avatarDir, { recursive: true });
      const name = `${uid.replace(/[^A-Za-z0-9_-]/g, "_")}-${Date.now()}.${ext}`;
      await writeFile(path.join(config.avatarDir, name), bytes);
      const updated = await setPhoto(uid, `${prefix}${name}`);
      await removeHosted(rows[0].photo_url);
      return userJson(updated);
    });

    app.delete("/v1/me/avatar", async (req) => {
      const { uid } = caller(req);
      const { rows } = await db.query<UserRow>("SELECT * FROM users WHERE id = $1", [uid]);
      if (!rows[0]) throw notFound("User");
      const updated = await setPhoto(uid, null);
      await removeHosted(rows[0].photo_url);
      return userJson(updated);
    });

    app.get<{ Params: { file: string } }>("/avatars/:file", async (req, reply) => {
      const { file } = req.params;
      if (!SAFE_FILE.test(file)) throw notFound("Avatar");
      const full = path.join(config.avatarDir, file);
      try {
        await stat(full);
      } catch {
        throw notFound("Avatar");
      }
      const ext = file.split(".").pop()!;
      const type = Object.entries(EXTENSIONS).find(([, e]) => e === ext)?.[0] ?? "application/octet-stream";
      // File names are unique per upload, so they never change.
      return reply
        .header("content-type", type)
        .header("cache-control", "public, max-age=31536000, immutable")
        .send(createReadStream(full));
    });
  };
}

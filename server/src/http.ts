import type { FastifyRequest } from "fastify";
import { z } from "zod";
import type { AuthUser } from "./auth.js";
import { ApiError, validation } from "./errors.js";

declare module "fastify" {
  interface FastifyRequest {
    auth: AuthUser | null;
  }
}

export function caller(req: FastifyRequest): AuthUser {
  if (!req.auth) throw new ApiError("unauthenticated", "Sign in required");
  return req.auth;
}

export function parse<T extends z.ZodType>(schema: T, value: unknown): z.infer<T> {
  const result = schema.safeParse(value ?? {});
  if (!result.success) {
    throw validation(result.error.issues.map((i) => `${i.path.join(".") || "body"}: ${i.message}`).join("; "));
  }
  return result.data;
}

export const isoDate = z.iso.datetime({ offset: true }).transform((s) => new Date(s));
export const idList = z.array(z.string().min(1));

import { createRemoteJWKSet, jwtVerify } from "jose";
import { ApiError } from "./errors.js";

export interface AuthUser {
  uid: string;
  email: string | null;
}

/** Verifies a bearer token and returns the caller. Throws on invalid tokens. */
export type TokenVerifier = (token: string) => Promise<AuthUser>;

const FIREBASE_JWKS = new URL(
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
);

/**
 * Firebase ID tokens are RS256 JWTs signed by Google. Verifying them against
 * the public JWKS needs no service account, so the server holds no Firebase
 * secret at all.
 */
export function firebaseVerifier(projectId: string): TokenVerifier {
  const jwks = createRemoteJWKSet(FIREBASE_JWKS);
  return async (token) => {
    try {
      const { payload } = await jwtVerify(token, jwks, {
        issuer: `https://securetoken.google.com/${projectId}`,
        audience: projectId,
        algorithms: ["RS256"],
      });
      if (!payload.sub) throw new Error("missing sub");
      return {
        uid: payload.sub,
        email: typeof payload.email === "string" ? payload.email : null,
      };
    } catch {
      throw new ApiError("unauthenticated", "Invalid or expired token");
    }
  };
}

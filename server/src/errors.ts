export type ErrorCode =
  | "unauthenticated"
  | "forbidden"
  | "not_found"
  | "validation"
  | "concurrent_update"
  | "conflict";

const STATUS: Record<ErrorCode, number> = {
  unauthenticated: 401,
  forbidden: 403,
  not_found: 404,
  validation: 400,
  concurrent_update: 409,
  conflict: 409,
};

export class ApiError extends Error {
  readonly statusCode: number;

  constructor(readonly code: ErrorCode, message: string = code) {
    super(message);
    this.statusCode = STATUS[code];
  }
}

export const notFound = (what: string) => new ApiError("not_found", `${what} not found`);
export const forbidden = (message = "Not allowed") => new ApiError("forbidden", message);
export const validation = (message: string) => new ApiError("validation", message);

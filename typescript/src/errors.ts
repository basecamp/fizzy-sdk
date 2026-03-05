/**
 * Structured error types for the Fizzy SDK.
 *
 * Provides typed errors with error codes, hints, and exit codes
 * for CLI-friendly error handling.
 */

const MAX_ERROR_MESSAGE_LENGTH = 500;

function truncateErrorMessage(s: string, maxLen: number = MAX_ERROR_MESSAGE_LENGTH): string {
  if (s.length <= maxLen) return s;
  return s.slice(0, maxLen - 3) + "...";
}

/**
 * Error codes for categorizing Fizzy API errors.
 */
export type ErrorCode =
  | "auth_required"
  | "forbidden"
  | "not_found"
  | "rate_limit"
  | "validation"
  | "ambiguous"
  | "network"
  | "api_error"
  | "usage";

/**
 * Options for creating a FizzyError.
 */
export interface FizzyErrorOptions {
  /** User-friendly hint for resolving the error */
  hint?: string;
  /** HTTP status code that caused the error */
  httpStatus?: number;
  /** Whether the operation can be retried */
  retryable?: boolean;
  /** Original error that caused this error */
  cause?: Error;
  /** Number of seconds to wait before retrying (for rate limits) */
  retryAfter?: number;
  /** Request ID from the server for debugging */
  requestId?: string;
}

const EXIT_CODES: Record<ErrorCode, number> = {
  usage: 1,
  not_found: 2,
  auth_required: 3,
  forbidden: 4,
  rate_limit: 5,
  network: 6,
  api_error: 7,
  ambiguous: 8,
  validation: 9,
};

/**
 * Structured error class for Fizzy API errors.
 */
export class FizzyError extends Error {
  readonly code: ErrorCode;
  readonly hint?: string;
  readonly httpStatus?: number;
  readonly retryable: boolean;
  readonly retryAfter?: number;
  readonly requestId?: string;
  declare readonly cause?: Error;

  constructor(code: ErrorCode, message: string, options?: FizzyErrorOptions) {
    super(message);
    this.name = "FizzyError";
    this.code = code;
    this.hint = options?.hint;
    this.httpStatus = options?.httpStatus;
    this.retryable = options?.retryable ?? false;
    this.retryAfter = options?.retryAfter;
    this.requestId = options?.requestId;

    if (options?.cause) {
      this.cause = options.cause;
    }

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, FizzyError);
    }
  }

  get exitCode(): number {
    return EXIT_CODES[this.code];
  }

  toJSON(): Record<string, unknown> {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      hint: this.hint,
      httpStatus: this.httpStatus,
      retryable: this.retryable,
      retryAfter: this.retryAfter,
      requestId: this.requestId,
    };
  }
}

/**
 * Factory functions for creating common error types.
 */
export const Errors = {
  auth: (hint?: string, cause?: Error): FizzyError =>
    new FizzyError("auth_required", "Authentication required", {
      hint: hint ?? "Check your access token or cookie session",
      httpStatus: 401,
      cause,
    }),

  forbidden: (hint?: string, cause?: Error): FizzyError =>
    new FizzyError("forbidden", "Access denied", {
      hint: hint ?? "You do not have permission to access this resource",
      httpStatus: 403,
      cause,
    }),

  notFound: (resource: string, id?: number | string): FizzyError =>
    new FizzyError(
      "not_found",
      id ? `${resource} ${id} not found` : `${resource} not found`,
      { httpStatus: 404 }
    ),

  rateLimit: (retryAfter?: number, cause?: Error): FizzyError =>
    new FizzyError("rate_limit", "Rate limit exceeded", {
      retryable: true,
      httpStatus: 429,
      hint: retryAfter ? `Retry after ${retryAfter} seconds` : "Please slow down requests",
      retryAfter,
      cause,
    }),

  validation: (message: string, hint?: string): FizzyError =>
    new FizzyError("validation", message, {
      httpStatus: 400,
      hint,
    }),

  ambiguous: (resource: string, matches: string[]): FizzyError => {
    const hint = matches.length > 0 && matches.length <= 5
      ? `Did you mean: ${matches.join(", ")}`
      : "Be more specific";
    return new FizzyError("ambiguous", `Ambiguous ${resource}`, { hint });
  },

  network: (message: string, cause?: Error): FizzyError =>
    new FizzyError("network", message, {
      retryable: true,
      hint: "Check your network connection",
      cause,
    }),

  apiError: (
    message: string,
    httpStatus?: number,
    options?: Pick<FizzyErrorOptions, "hint" | "retryable" | "requestId" | "cause">
  ): FizzyError =>
    new FizzyError("api_error", message, {
      httpStatus,
      ...options,
    }),
};

/**
 * Creates a FizzyError from an HTTP response.
 */
export async function errorFromResponse(
  response: Response,
  requestId?: string
): Promise<FizzyError> {
  const httpStatus = response.status;
  const retryAfter = parseRetryAfter(response.headers.get("Retry-After"));

  let message = response.statusText || "Request failed";
  let hint: string | undefined;

  try {
    const body = await response.json();
    if (typeof body === "object" && body !== null) {
      if ("error" in body && typeof body.error === "string") {
        message = truncateErrorMessage(body.error);
      }
      if ("error_description" in body && typeof body.error_description === "string") {
        hint = truncateErrorMessage(body.error_description);
      }
    }
  } catch {
    // Body is not JSON or empty
  }

  switch (httpStatus) {
    case 401:
      return new FizzyError("auth_required", message, { httpStatus, hint, requestId });
    case 403:
      return new FizzyError("forbidden", message, { httpStatus, hint, requestId });
    case 404:
      return new FizzyError("not_found", message, { httpStatus, hint, requestId });
    case 429:
      return new FizzyError("rate_limit", message, {
        httpStatus,
        retryable: true,
        retryAfter,
        hint: retryAfter ? `Retry after ${retryAfter} seconds` : hint,
        requestId,
      });
    case 400:
    case 422:
      return new FizzyError("validation", message, { httpStatus, hint, requestId });
    default: {
      const retryable = httpStatus >= 500 && httpStatus < 600;
      return new FizzyError("api_error", message, {
        httpStatus,
        retryable,
        hint,
        requestId,
      });
    }
  }
}

function parseRetryAfter(value: string | null): number | undefined {
  if (!value) return undefined;

  const seconds = parseInt(value, 10);
  if (!isNaN(seconds) && seconds > 0) {
    return seconds;
  }

  const date = Date.parse(value);
  if (!isNaN(date)) {
    const diffMs = date - Date.now();
    if (diffMs > 0) {
      return Math.ceil(diffMs / 1000);
    }
  }

  return undefined;
}

/**
 * Type guard to check if an error is a FizzyError.
 */
export function isFizzyError(error: unknown): error is FizzyError {
  return error instanceof FizzyError;
}

/**
 * Type guard to check if an error is a specific type of FizzyError.
 */
export function isErrorCode(error: unknown, code: ErrorCode): error is FizzyError {
  return isFizzyError(error) && error.code === code;
}

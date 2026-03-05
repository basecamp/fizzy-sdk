/**
 * Security utilities for the Fizzy SDK.
 *
 * Provides helpers for safely logging HTTP requests without exposing
 * sensitive information like tokens and cookies.
 */

const SENSITIVE_HEADERS = [
  "authorization",
  "cookie",
  "set-cookie",
  "x-csrf-token",
];

/**
 * Returns a copy of the headers with sensitive values replaced by "[REDACTED]".
 */
export function redactHeaders(headers: Headers): Record<string, string> {
  const result: Record<string, string> = {};

  headers.forEach((value, key) => {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_HEADERS.includes(lowerKey)) {
      result[key] = "[REDACTED]";
    } else {
      result[key] = value;
    }
  });

  return result;
}

/**
 * Returns a copy of the header record with sensitive values replaced by "[REDACTED]".
 */
export function redactHeadersRecord(
  headers: Record<string, string>
): Record<string, string> {
  const result: Record<string, string> = {};

  for (const [key, value] of Object.entries(headers)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_HEADERS.includes(lowerKey)) {
      result[key] = "[REDACTED]";
    } else {
      result[key] = value;
    }
  }

  return result;
}

/**
 * Checks if a hostname represents localhost for development/testing purposes.
 */
export function isLocalhost(hostname: string): boolean {
  const normalized = hostname.toLowerCase();
  return (
    normalized === "localhost" ||
    normalized === "127.0.0.1" ||
    normalized === "::1" ||
    normalized.endsWith(".localhost")
  );
}

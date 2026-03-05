/**
 * OpenTelemetry hooks for the Fizzy SDK.
 *
 * Provides distributed tracing and metrics for API operations.
 * Requires @opentelemetry/api as an optional peer dependency.
 */

import type { FizzyHooks, OperationInfo, OperationResult, RequestInfo, RequestResult } from "../hooks.js";

interface OtelSpan {
  setAttribute(key: string, value: string | number | boolean): this;
  setStatus(status: { code: number; message?: string }): this;
  recordException(exception: Error): this;
  end(): void;
}

interface OtelTracer {
  startSpan(name: string, options?: { attributes?: Record<string, string | number | boolean> }): OtelSpan;
}

interface OtelMeter {
  createHistogram(name: string, options?: { description?: string; unit?: string }): OtelHistogram;
  createCounter(name: string, options?: { description?: string }): OtelCounter;
}

interface OtelHistogram {
  record(value: number, attributes?: Record<string, string | number | boolean>): void;
}

interface OtelCounter {
  add(value: number, attributes?: Record<string, string | number | boolean>): void;
}

const SpanStatusCode = {
  UNSET: 0,
  OK: 1,
  ERROR: 2,
} as const;

export interface OtelHooksOptions {
  tracer?: OtelTracer;
  meter?: OtelMeter;
  recordRequestSpans?: boolean;
  spanPrefix?: string;
  metricPrefix?: string;
}

interface OtelState {
  operationSpans: WeakMap<OperationInfo, OtelSpan>;
  requestSpans: Map<string, OtelSpan>;
  requestKeyStack: Map<string, string[]>;
  operationDuration?: OtelHistogram;
  requestDuration?: OtelHistogram;
  operationCounter?: OtelCounter;
  errorCounter?: OtelCounter;
  retryCounter?: OtelCounter;
}

let keyCounter = 0;

function requestPrefix(info: RequestInfo): string {
  return `${info.method}:${info.url}:${info.attempt}`;
}

function requestKey(): string {
  return String(++keyCounter);
}

/**
 * Creates OpenTelemetry hooks for distributed tracing and metrics.
 */
export function otelHooks(options: OtelHooksOptions = {}): FizzyHooks {
  const {
    tracer,
    meter,
    recordRequestSpans = false,
    spanPrefix = "fizzy",
    metricPrefix = "fizzy",
  } = options;

  const state: OtelState = {
    operationSpans: new WeakMap(),
    requestSpans: new Map(),
    requestKeyStack: new Map(),
  };

  if (meter) {
    state.operationDuration = meter.createHistogram(`${metricPrefix}.operation.duration`, {
      description: "Duration of Fizzy SDK operations",
      unit: "ms",
    });
    state.requestDuration = meter.createHistogram(`${metricPrefix}.request.duration`, {
      description: "Duration of HTTP requests",
      unit: "ms",
    });
    state.operationCounter = meter.createCounter(`${metricPrefix}.operations.total`, {
      description: "Total number of Fizzy SDK operations",
    });
    state.errorCounter = meter.createCounter(`${metricPrefix}.errors.total`, {
      description: "Total number of errors",
    });
    state.retryCounter = meter.createCounter(`${metricPrefix}.retries.total`, {
      description: "Total number of retry attempts",
    });
  }

  return {
    onOperationStart(info: OperationInfo): void {
      state.operationCounter?.add(1, {
        service: info.service,
        operation: info.operation,
        is_mutation: info.isMutation,
      });

      if (!tracer) return;

      const spanName = `${spanPrefix}.${info.service}.${info.operation}`;
      const attributes: Record<string, string | number | boolean> = {
        [`${spanPrefix}.service`]: info.service,
        [`${spanPrefix}.operation`]: info.operation,
        [`${spanPrefix}.resource_type`]: info.resourceType,
        [`${spanPrefix}.is_mutation`]: info.isMutation,
      };

      if (info.boardId) {
        attributes[`${spanPrefix}.board_id`] = info.boardId;
      }
      if (info.resourceId) {
        attributes[`${spanPrefix}.resource_id`] = info.resourceId;
      }

      const span = tracer.startSpan(spanName, { attributes });
      state.operationSpans.set(info, span);
    },

    onOperationEnd(info: OperationInfo, result: OperationResult): void {
      if (tracer) {
        const span = state.operationSpans.get(info);
        if (span) {
          if (result.error) {
            span.setStatus({ code: SpanStatusCode.ERROR, message: result.error.message });
            span.recordException(result.error);
            span.setAttribute("error", true);
            span.setAttribute("error.message", result.error.message);
          } else {
            span.setStatus({ code: SpanStatusCode.OK });
          }
          span.setAttribute("duration_ms", result.durationMs);
          span.end();
          state.operationSpans.delete(info);
        }
      }

      const labels = {
        service: info.service,
        operation: info.operation,
        is_mutation: info.isMutation,
        success: !result.error,
      };

      state.operationDuration?.record(result.durationMs, labels);

      if (result.error) {
        state.errorCounter?.add(1, {
          service: info.service,
          operation: info.operation,
          error_type: result.error.name,
        });
      }
    },

    onRequestStart(info: RequestInfo): void {
      if (!tracer || !recordRequestSpans) return;

      const spanName = `${spanPrefix}.http.${info.method}`;
      const span = tracer.startSpan(spanName, {
        attributes: {
          "http.method": info.method,
          "http.url": info.url,
          "http.attempt": info.attempt,
        },
      });

      const key = requestKey();
      state.requestSpans.set(key, span);

      const prefix = requestPrefix(info);
      let stack = state.requestKeyStack.get(prefix);
      if (!stack) {
        stack = [];
        state.requestKeyStack.set(prefix, stack);
      }
      stack.push(key);
    },

    onRequestEnd(info: RequestInfo, result: RequestResult): void {
      if (tracer && recordRequestSpans) {
        const prefix = requestPrefix(info);
        const stack = state.requestKeyStack.get(prefix);
        const key = stack?.pop();

        if (key) {
          if (stack!.length === 0) {
            state.requestKeyStack.delete(prefix);
          }

          const span = state.requestSpans.get(key);
          if (span) {
            span.setAttribute("http.status_code", result.statusCode);
            span.setAttribute("http.from_cache", result.fromCache);
            span.setAttribute("duration_ms", result.durationMs);

            if (result.error) {
              span.setStatus({ code: SpanStatusCode.ERROR, message: result.error.message });
              span.recordException(result.error);
            } else if (result.statusCode >= 400) {
              span.setStatus({ code: SpanStatusCode.ERROR, message: `HTTP ${result.statusCode}` });
            } else {
              span.setStatus({ code: SpanStatusCode.OK });
            }

            span.end();
            state.requestSpans.delete(key);
          }
        }
      }

      state.requestDuration?.record(result.durationMs, {
        method: info.method,
        status_code: result.statusCode,
        from_cache: result.fromCache,
      });
    },

    onRetry(info: RequestInfo, attempt: number, error: Error, _delayMs: number): void {
      state.retryCounter?.add(1, {
        method: info.method,
        attempt,
        error_type: error.name,
      });
    },
  };
}

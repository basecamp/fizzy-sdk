/**
 * Base service class for Fizzy API services.
 *
 * Provides shared functionality for all service classes including:
 * - Error handling with typed FizzyError
 * - Hooks integration for observability
 * - Automatic pagination via Link headers
 */

import type { FizzyHooks, OperationInfo, OperationResult } from "../hooks.js";
import { FizzyError, errorFromResponse } from "../errors.js";
import { ListResult, type PaginationOptions } from "../pagination.js";
import { parseNextLink, resolveURL, isSameOrigin } from "../pagination-utils.js";
import type { paths } from "../generated/schema.js";
import type createClient from "openapi-fetch";

/**
 * Raw client type from openapi-fetch.
 */
export type RawClient = ReturnType<typeof createClient<paths>>;

/**
 * Response type from openapi-fetch methods.
 */
export interface FetchResponse<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

/** Maximum pages to follow as a safety cap against infinite loops. */
const MAX_PAGES = 10_000;

/**
 * Abstract base class for all Fizzy API services.
 */
export abstract class BaseService {
  protected readonly client: RawClient;
  protected readonly hooks?: FizzyHooks;

  /**
   * Authenticated fetch for pagination follow-up requests.
   * Provided by createFizzyClient; falls back to unauthenticated fetch.
   */
  protected readonly fetchPage: (url: string) => Promise<Response>;

  constructor(
    client: RawClient,
    hooks?: FizzyHooks,
    fetchPage?: (url: string) => Promise<Response>,
  ) {
    this.client = client;
    this.hooks = hooks;
    this.fetchPage = fetchPage ?? ((url) => fetch(url, { headers: { Accept: "application/json" } }));
  }

  /**
   * Executes an API request with error handling and hooks integration.
   */
  protected async request<T>(
    info: OperationInfo,
    fn: () => Promise<FetchResponse<T>>
  ): Promise<T> {
    const start = performance.now();
    let result: OperationResult = { durationMs: 0 };

    try { this.hooks?.onOperationStart?.(info); } catch { /* hooks must not interrupt */ }

    try {
      const { data, error, response } = await fn();
      result.durationMs = Math.round(performance.now() - start);

      if (!response.ok || error) {
        const fizzyError = await this.handleError(response, error);
        result.error = fizzyError;
        throw fizzyError;
      }

      if (response.status === 204 || data === undefined) {
        return undefined as T;
      }

      return data;
    } catch (err) {
      result.durationMs = Math.round(performance.now() - start);
      if (err instanceof Error) {
        result.error = err;
      }
      throw err;
    } finally {
      try { this.hooks?.onOperationEnd?.(info, result); } catch { /* hooks must not interrupt */ }
    }
  }

  /**
   * Executes a paginated API request, automatically following Link headers.
   * Returns a ListResult<T> which extends Array<T>.
   * Fizzy does not emit X-Total-Count.
   */
  protected async requestPaginated<T>(
    info: OperationInfo,
    fn: () => Promise<FetchResponse<T[]>>,
    paginationOpts?: PaginationOptions,
  ): Promise<ListResult<T>> {
    const start = performance.now();
    let result: OperationResult = { durationMs: 0 };

    try { this.hooks?.onOperationStart?.(info); } catch { /* hooks must not interrupt */ }

    try {
      const { data, error, response } = await fn();
      result.durationMs = Math.round(performance.now() - start);

      if (!response.ok || error) {
        const fizzyError = await this.handleError(response, error);
        result.error = fizzyError;
        throw fizzyError;
      }

      const firstPageItems: T[] = data ?? [];
      const maxItems = paginationOpts?.maxItems;

      if (maxItems && maxItems > 0 && firstPageItems.length >= maxItems) {
        const hasMore = firstPageItems.length > maxItems
          || parseNextLink(response.headers.get("Link")) !== null;
        result.durationMs = Math.round(performance.now() - start);
        return new ListResult(firstPageItems.slice(0, maxItems), { truncated: hasMore });
      }

      const { items: allItems, truncated } = await this.followPagination(
        response,
        firstPageItems,
        maxItems,
      );

      result.durationMs = Math.round(performance.now() - start);
      return new ListResult(allItems, { truncated });
    } catch (err) {
      result.durationMs = Math.round(performance.now() - start);
      if (err instanceof Error) {
        result.error = err;
      }
      throw err;
    } finally {
      try { this.hooks?.onOperationEnd?.(info, result); } catch { /* hooks must not interrupt */ }
    }
  }

  private async followPagination<T>(
    initialResponse: Response,
    firstPageItems: T[],
    maxItems: number | undefined,
  ): Promise<{ items: T[]; truncated: boolean }> {
    const allItems = [...firstPageItems];
    let response = initialResponse;
    const initialUrl = initialResponse.url;

    for (let page = 1; page < MAX_PAGES; page++) {
      const rawNextUrl = parseNextLink(response.headers.get("Link"));
      if (!rawNextUrl) break;

      const nextUrl = resolveURL(response.url, rawNextUrl);

      if (!isSameOrigin(nextUrl, initialUrl)) {
        throw new FizzyError(
          "api_error",
          `Pagination Link header points to different origin: ${nextUrl}`,
        );
      }

      response = await this.fetchPage(nextUrl);

      if (!response.ok) {
        throw await errorFromResponse(response, response.headers.get("X-Request-Id") ?? undefined);
      }

      const pageItems: T[] = (await response.json()) as T[];
      allItems.push(...pageItems);

      if (maxItems && maxItems > 0 && allItems.length >= maxItems) {
        return { items: allItems.slice(0, maxItems), truncated: true };
      }
    }

    const hasMore = parseNextLink(response.headers.get("Link")) !== null;
    return { items: allItems, truncated: hasMore };
  }

  protected async handleError(response: Response, error?: unknown): Promise<FizzyError> {
    if (error instanceof FizzyError) {
      return error;
    }
    const requestId = response.headers.get("X-Request-Id") ?? undefined;
    return errorFromResponse(response, requestId);
  }
}

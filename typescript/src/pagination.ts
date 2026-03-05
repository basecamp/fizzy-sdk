/**
 * Pagination types and utilities for the Fizzy SDK.
 *
 * Provides ListResult (an Array subclass with metadata) and pagination options.
 * Fizzy does not emit X-Total-Count headers — totalCount is not available.
 */

/**
 * Metadata about a paginated list response.
 * Note: Fizzy does not provide a total count header.
 */
export interface ListMeta {
  /** True when results were truncated (by maxItems or page safety cap). */
  readonly truncated: boolean;
}

/**
 * Options for controlling pagination behavior.
 */
export interface PaginationOptions {
  /**
   * Maximum number of items to return across all pages.
   * When undefined or 0, all pages are fetched.
   */
  maxItems?: number;
}

/**
 * An array of results with pagination metadata.
 *
 * Extends Array<T> so it's fully backwards-compatible: works with
 * .forEach(), .map(), spread, .length, indexing, and Array.isArray().
 * Additional metadata is accessible via the `.meta` property.
 */
export class ListResult<T> extends Array<T> {
  readonly meta: ListMeta;

  static get [Symbol.species](): ArrayConstructor {
    return Array;
  }

  constructor(items: T[], meta: ListMeta) {
    super(0);
    if (items.length > 0) {
      this.length = items.length;
      for (let i = 0; i < items.length; i++) {
        this[i] = items[i]!;
      }
    }
    this.meta = meta;
  }
}

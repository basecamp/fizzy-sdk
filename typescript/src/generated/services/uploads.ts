/**
 * Uploads service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type DirectUpload = components["schemas"]["DirectUpload"];

export interface CreateDirectUploadRequest {
  /** File name */
  filename: string;
  /** MIME content type */
  contentType: string;
  /** File size in bytes */
  byteSize: number;
  /** MD5 checksum (base64-encoded) */
  checksum: string;
}

export class UploadsService extends BaseService {

  async createDirect(body: CreateDirectUploadRequest): Promise<DirectUpload> {
    return this.request(
      { service: "Uploads", operation: "CreateDirect", resourceType: "direct_upload", isMutation: true },
      () => this.client.POST("/uploads.json" as never, {
        body: {
          filename: body.filename,
          content_type: body.contentType,
          byte_size: body.byteSize,
          checksum: body.checksum,
        } as never,
      } as never),
    );
  }
}

/**
 * Uploads service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type DirectUpload = components["schemas"]["DirectUpload"];

export interface CreateDirectUploadRequest {
  filename: string;
  contentType: string;
  byteSize: number;
  checksum: string;
}

export class UploadsService extends BaseService {

  /**
   * CreateDirectUpload
   */
  async createDirect(body: CreateDirectUploadRequest): Promise<DirectUpload> {
    return this.request(
      {
        service: "Direct upload",
        operation: "CreateDirectUpload",
        resourceType: "direct_upload",
        isMutation: true,
      },
      () => this.client.POST("/rails/active_storage/direct_uploads" as never, {
        body: { filename: body.filename, content_type: body.contentType, byte_size: body.byteSize, checksum: body.checksum } as never,
      } as never),
    );
  }
}

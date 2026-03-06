// Package generated provides type aliases mapping service-layer names to
// Smithy-generated schema names from oapi-codegen.
//
// The Smithy model uses *RequestContent / *ResponseContent suffixes.
// The service layer uses shorter *Request names for ergonomics.
package generated

// Request type aliases (service-layer name = generated name)
type AssignCardRequest = AssignCardRequestContent
type BulkReadNotificationsRequest = BulkReadNotificationsRequestContent
type CompleteSignupRequest = CompleteSignupRequestContent
type CreateBoardRequest = CreateBoardRequestContent
type CreateCardRequest = CreateCardRequestContent
type CreateColumnRequest = CreateColumnRequestContent
type CreateCommentRequest = CreateCommentRequestContent
type CreateDirectUploadRequest = CreateDirectUploadRequestContent
type CreateReactionRequest = CreateCardReactionRequestContent
type CreateSessionRequest = CreateSessionRequestContent
type CreateStepRequest = CreateStepRequestContent
type CreateWebhookRequest = CreateWebhookRequestContent
type MoveCardRequest = MoveCardRequestContent
type RedeemMagicLinkRequest = RedeemMagicLinkRequestContent
type RegisterDeviceRequest = RegisterDeviceRequestContent
type TagCardRequest = TagCardRequestContent
// TriageCardRequest is a stub — TriageCard has no request body in the spec.
type TriageCardRequest struct{}
type UpdateBoardRequest = UpdateBoardRequestContent
type UpdateCardRequest = UpdateCardRequestContent
type UpdateColumnRequest = UpdateColumnRequestContent
type UpdateCommentRequest = UpdateCommentRequestContent
type UpdateStepRequest = UpdateStepRequestContent
type UpdateUserRequest = UpdateUserRequestContent
type UpdateWebhookRequest = UpdateWebhookRequestContent

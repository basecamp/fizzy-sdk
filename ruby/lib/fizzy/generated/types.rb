# frozen_string_literal: true

# @generated from OpenAPI spec — do not edit by hand
#
# These types provide structured access to API response data.
# Each type is a Data.define (Ruby 3.2+) with keyword initialization.

module Fizzy
  module Types
    # @generated
    AccessToken = Data.define(:id, :description, :permission, :created_at, :token) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          description: data["description"],
          permission: data["permission"],
          created_at: data["created_at"],
          token: data["token"]
        )
      end
    end

    # @generated
    Account = Data.define(:id, :name, :slug, :created_at, :url, :user) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          slug: data["slug"],
          created_at: data["created_at"],
          url: data["url"],
          user: data["user"]
        )
      end
    end

    # @generated
    AccountExport = Data.define(:id, :status, :created_at, :download_url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          status: data["status"],
          created_at: data["created_at"],
          download_url: data["download_url"]
        )
      end
    end

    # @generated
    AccountSettings = Data.define(:id, :name, :cards_count, :created_at, :auto_postpone_period_in_days) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          cards_count: data["cards_count"],
          created_at: data["created_at"],
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"]
        )
      end
    end

    # @generated
    Activity = Data.define(:id, :action, :created_at, :description, :particulars, :url, :eventable_type, :eventable, :board, :creator) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          action: data["action"],
          created_at: data["created_at"],
          description: data["description"],
          particulars: data["particulars"],
          url: data["url"],
          eventable_type: data["eventable_type"],
          eventable: data["eventable"],
          board: data["board"],
          creator: data["creator"]
        )
      end
    end

    # @generated
    ActivityEventable = Data.define(:id, :number, :title, :status, :description, :description_html, :image_url, :has_attachments, :tags, :closed, :postponed, :golden, :last_active_at, :created_at, :updated_at, :body, :creator, :card, :board, :column, :assignees, :has_more_assignees, :comments_url, :reactions_url, :steps, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          number: data["number"],
          title: data["title"],
          status: data["status"],
          description: data["description"],
          description_html: data["description_html"],
          image_url: data["image_url"],
          has_attachments: data["has_attachments"],
          tags: data["tags"],
          closed: data["closed"],
          postponed: data["postponed"],
          golden: data["golden"],
          last_active_at: data["last_active_at"],
          created_at: data["created_at"],
          updated_at: data["updated_at"],
          body: data["body"],
          creator: data["creator"],
          card: data["card"],
          board: data["board"],
          column: data["column"],
          assignees: data["assignees"],
          has_more_assignees: data["has_more_assignees"],
          comments_url: data["comments_url"],
          reactions_url: data["reactions_url"],
          steps: data["steps"],
          url: data["url"]
        )
      end
    end

    # @generated
    ActivityParticulars = Data.define(:assignee_ids, :old_board, :new_board, :old_title, :new_title, :column) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          assignee_ids: data["assignee_ids"],
          old_board: data["old_board"],
          new_board: data["new_board"],
          old_title: data["old_title"],
          new_title: data["new_title"],
          column: data["column"]
        )
      end
    end

    # @generated
    AssignCardRequestContent = Data.define(:assignee_id) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          assignee_id: data["assignee_id"]
        )
      end
    end

    # @generated
    BadRequestErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    Board = Data.define(:id, :name, :all_access, :created_at, :auto_postpone_period_in_days, :public_description, :public_description_html, :public_url, :user_ids, :url, :creator) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          all_access: data["all_access"],
          created_at: data["created_at"],
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"],
          public_description: data["public_description"],
          public_description_html: data["public_description_html"],
          public_url: data["public_url"],
          user_ids: data["user_ids"],
          url: data["url"],
          creator: data["creator"]
        )
      end
    end

    # @generated
    BoardAccessUser = Data.define(:id, :name, :role, :active, :email_address, :created_at, :url, :avatar_url, :has_access, :involvement) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          role: data["role"],
          active: data["active"],
          email_address: data["email_address"],
          created_at: data["created_at"],
          url: data["url"],
          avatar_url: data["avatar_url"],
          has_access: data["has_access"],
          involvement: data["involvement"]
        )
      end
    end

    # @generated
    BoardAccesses = Data.define(:board_id, :all_access, :users) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          board_id: data["board_id"],
          all_access: data["all_access"],
          users: data["users"]
        )
      end
    end

    # @generated
    BulkReadNotificationsRequestContent = Data.define(:notification_ids) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          notification_ids: data["notification_ids"]
        )
      end
    end

    # @generated
    Card = Data.define(:id, :number, :title, :status, :description, :description_html, :image_url, :has_attachments, :tags, :closed, :postponed, :golden, :last_active_at, :created_at, :url, :board, :column, :creator, :assignees, :has_more_assignees, :comments_url, :reactions_url, :steps) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          number: data["number"],
          title: data["title"],
          status: data["status"],
          description: data["description"],
          description_html: data["description_html"],
          image_url: data["image_url"],
          has_attachments: data["has_attachments"],
          tags: data["tags"],
          closed: data["closed"],
          postponed: data["postponed"],
          golden: data["golden"],
          last_active_at: data["last_active_at"],
          created_at: data["created_at"],
          url: data["url"],
          board: data["board"],
          column: data["column"],
          creator: data["creator"],
          assignees: data["assignees"],
          has_more_assignees: data["has_more_assignees"],
          comments_url: data["comments_url"],
          reactions_url: data["reactions_url"],
          steps: data["steps"]
        )
      end
    end

    # @generated
    CardRef = Data.define(:id, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          url: data["url"]
        )
      end
    end

    # @generated
    Column = Data.define(:id, :name, :color, :created_at, :cards_url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          color: data["color"],
          created_at: data["created_at"],
          cards_url: data["cards_url"]
        )
      end
    end

    # @generated
    Comment = Data.define(:id, :created_at, :updated_at, :body, :creator, :card, :reactions_url, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          created_at: data["created_at"],
          updated_at: data["updated_at"],
          body: data["body"],
          creator: data["creator"],
          card: data["card"],
          reactions_url: data["reactions_url"],
          url: data["url"]
        )
      end
    end

    # @generated
    CompleteJoinRequestContent = Data.define(:name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"]
        )
      end
    end

    # @generated
    CompleteSignupRequestContent = Data.define(:full_name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          full_name: data["full_name"]
        )
      end
    end

    # @generated
    CreateAccessTokenRequestContent = Data.define(:description, :permission) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          description: data["description"],
          permission: data["permission"]
        )
      end
    end

    # @generated
    CreateAccessTokenResponseContent = Data.define

    # @generated
    CreateAccountExportResponseContent = Data.define

    # @generated
    CreateBoardRequestContent = Data.define(:name, :all_access, :auto_postpone_period_in_days, :public_description) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          all_access: data["all_access"],
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"],
          public_description: data["public_description"]
        )
      end
    end

    # @generated
    CreateBoardResponseContent = Data.define

    # @generated
    CreateCardReactionRequestContent = Data.define(:content) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          content: data["content"]
        )
      end
    end

    # @generated
    CreateCardReactionResponseContent = Data.define

    # @generated
    CreateCardRequestContent = Data.define(:title, :board_id, :column_id, :description, :assignee_ids, :tag_names, :image, :created_at, :last_active_at) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          title: data["title"],
          board_id: data["board_id"],
          column_id: data["column_id"],
          description: data["description"],
          assignee_ids: data["assignee_ids"],
          tag_names: data["tag_names"],
          image: data["image"],
          created_at: data["created_at"],
          last_active_at: data["last_active_at"]
        )
      end
    end

    # @generated
    CreateCardResponseContent = Data.define

    # @generated
    CreateColumnRequestContent = Data.define(:name, :color) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          color: data["color"]
        )
      end
    end

    # @generated
    CreateColumnResponseContent = Data.define

    # @generated
    CreateCommentReactionRequestContent = Data.define(:content) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          content: data["content"]
        )
      end
    end

    # @generated
    CreateCommentReactionResponseContent = Data.define

    # @generated
    CreateCommentRequestContent = Data.define(:body, :created_at) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          body: data["body"],
          created_at: data["created_at"]
        )
      end
    end

    # @generated
    CreateCommentResponseContent = Data.define

    # @generated
    CreateDirectUploadRequestContent = Data.define(:filename, :content_type, :byte_size, :checksum) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          filename: data["filename"],
          content_type: data["content_type"],
          byte_size: data["byte_size"],
          checksum: data["checksum"]
        )
      end
    end

    # @generated
    CreateDirectUploadResponseContent = Data.define

    # @generated
    CreatePushSubscriptionRequestContent = Data.define(:endpoint, :p256dh_key, :auth_key) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          endpoint: data["endpoint"],
          p256dh_key: data["p256dh_key"],
          auth_key: data["auth_key"]
        )
      end
    end

    # @generated
    CreateSessionRequestContent = Data.define(:email_address) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          email_address: data["email_address"]
        )
      end
    end

    # @generated
    CreateSessionResponseContent = Data.define

    # @generated
    CreateStepRequestContent = Data.define(:content, :completed) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          content: data["content"],
          completed: data["completed"]
        )
      end
    end

    # @generated
    CreateStepResponseContent = Data.define

    # @generated
    CreateUserDataExportResponseContent = Data.define

    # @generated
    CreateWebhookRequestContent = Data.define(:name, :url, :subscribed_actions) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          url: data["url"],
          subscribed_actions: data["subscribed_actions"]
        )
      end
    end

    # @generated
    CreateWebhookResponseContent = Data.define

    # @generated
    DataExport = Data.define(:id, :status, :created_at, :download_url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          status: data["status"],
          created_at: data["created_at"],
          download_url: data["download_url"]
        )
      end
    end

    # @generated
    DirectUpload = Data.define(:id, :key, :filename, :content_type, :byte_size, :checksum, :direct_upload) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          key: data["key"],
          filename: data["filename"],
          content_type: data["content_type"],
          byte_size: data["byte_size"],
          checksum: data["checksum"],
          direct_upload: data["direct_upload"]
        )
      end
    end

    # @generated
    DirectUploadHeaders = Data.define(:content_type, :content_md5) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          content_type: data["Content_Type"],
          content_md5: data["Content_MD5"]
        )
      end
    end

    # @generated
    DirectUploadMetadata = Data.define(:url, :headers) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          url: data["url"],
          headers: data["headers"]
        )
      end
    end

    # @generated
    ForbiddenErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    GetAccountExportResponseContent = Data.define

    # @generated
    GetAccountSettingsResponseContent = Data.define

    # @generated
    GetBoardResponseContent = Data.define

    # @generated
    GetCardResponseContent = Data.define

    # @generated
    GetColumnResponseContent = Data.define

    # @generated
    GetCommentResponseContent = Data.define

    # @generated
    GetJoinCodeResponseContent = Data.define

    # @generated
    GetMyIdentityResponseContent = Data.define

    # @generated
    GetNotificationSettingsResponseContent = Data.define

    # @generated
    GetNotificationTrayResponseContent = Data.define

    # @generated
    GetStepResponseContent = Data.define

    # @generated
    GetUserDataExportResponseContent = Data.define

    # @generated
    GetUserResponseContent = Data.define

    # @generated
    GetWebhookResponseContent = Data.define

    # @generated
    Identity = Data.define(:id, :name, :email_address, :accounts) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          email_address: data["email_address"],
          accounts: data["accounts"]
        )
      end
    end

    # @generated
    InternalServerErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    JoinCode = Data.define(:code, :url, :usage_count, :usage_limit, :active) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          code: data["code"],
          url: data["url"],
          usage_count: data["usage_count"],
          usage_limit: data["usage_limit"],
          active: data["active"]
        )
      end
    end

    # @generated
    ListAccessTokensResponseContent = Data.define

    # @generated
    ListActivitiesResponseContent = Data.define

    # @generated
    ListBoardAccessesResponseContent = Data.define

    # @generated
    ListBoardsResponseContent = Data.define

    # @generated
    ListCardReactionsResponseContent = Data.define

    # @generated
    ListCardsResponseContent = Data.define

    # @generated
    ListClosedCardsResponseContent = Data.define

    # @generated
    ListColumnCardsResponseContent = Data.define

    # @generated
    ListColumnsResponseContent = Data.define

    # @generated
    ListCommentReactionsResponseContent = Data.define

    # @generated
    ListCommentsResponseContent = Data.define

    # @generated
    ListNotificationsResponseContent = Data.define

    # @generated
    ListPinsResponseContent = Data.define

    # @generated
    ListPostponedCardsResponseContent = Data.define

    # @generated
    ListStepsResponseContent = Data.define

    # @generated
    ListStreamCardsResponseContent = Data.define

    # @generated
    ListTagsResponseContent = Data.define

    # @generated
    ListUsersResponseContent = Data.define

    # @generated
    ListWebhookDeliveriesResponseContent = Data.define

    # @generated
    ListWebhooksResponseContent = Data.define

    # @generated
    MoveCardRequestContent = Data.define(:board_id, :column_id) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          board_id: data["board_id"],
          column_id: data["column_id"]
        )
      end
    end

    # @generated
    MoveCardResponseContent = Data.define

    # @generated
    NotFoundErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    Notification = Data.define(:id, :unread_count, :read, :read_at, :created_at, :source_type, :title, :body, :creator, :card, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          unread_count: data["unread_count"],
          read: data["read"],
          read_at: data["read_at"],
          created_at: data["created_at"],
          source_type: data["source_type"],
          title: data["title"],
          body: data["body"],
          creator: data["creator"],
          card: data["card"],
          url: data["url"]
        )
      end
    end

    # @generated
    NotificationCard = Data.define(:id, :number, :title, :status, :board_name, :closed, :postponed, :url, :column) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          number: data["number"],
          title: data["title"],
          status: data["status"],
          board_name: data["board_name"],
          closed: data["closed"],
          postponed: data["postponed"],
          url: data["url"],
          column: data["column"]
        )
      end
    end

    # @generated
    NotificationSettings = Data.define(:bundle_email_frequency) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          bundle_email_frequency: data["bundle_email_frequency"]
        )
      end
    end

    # @generated
    PendingAuthentication = Data.define(:pending_authentication_token) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          pending_authentication_token: data["pending_authentication_token"]
        )
      end
    end

    # @generated
    RateLimitErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    Reaction = Data.define(:id, :content, :reacter, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          content: data["content"],
          reacter: data["reacter"],
          url: data["url"]
        )
      end
    end

    # @generated
    RedeemMagicLinkRequestContent = Data.define(:token) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          token: data["token"]
        )
      end
    end

    # @generated
    RedeemMagicLinkResponseContent = Data.define

    # @generated
    RegisterDeviceRequestContent = Data.define(:token, :platform, :name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          token: data["token"],
          platform: data["platform"],
          name: data["name"]
        )
      end
    end

    # @generated
    RequestEmailAddressChangeRequestContent = Data.define(:email_address) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          email_address: data["email_address"]
        )
      end
    end

    # @generated
    RichTextBody = Data.define(:plain_text, :html) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          plain_text: data["plain_text"],
          html: data["html"]
        )
      end
    end

    # @generated
    SearchCardsResponseContent = Data.define

    # @generated
    SessionAuthorization = Data.define(:session_token, :requires_signup_completion) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          session_token: data["session_token"],
          requires_signup_completion: data["requires_signup_completion"]
        )
      end
    end

    # @generated
    Step = Data.define(:id, :content, :completed) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          content: data["content"],
          completed: data["completed"]
        )
      end
    end

    # @generated
    StringMap = Data.define

    # @generated
    Tag = Data.define(:id, :title, :created_at, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          title: data["title"],
          created_at: data["created_at"],
          url: data["url"]
        )
      end
    end

    # @generated
    TagCardRequestContent = Data.define(:tag_title) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          tag_title: data["tag_title"]
        )
      end
    end

    # @generated
    TriageCardRequestContent = Data.define(:column_id) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          column_id: data["column_id"]
        )
      end
    end

    # @generated
    UnauthorizedErrorResponseContent = Data.define(:message) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"]
        )
      end
    end

    # @generated
    UpdateAccountEntropyRequestContent = Data.define(:auto_postpone_period_in_days) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"]
        )
      end
    end

    # @generated
    UpdateAccountEntropyResponseContent = Data.define

    # @generated
    UpdateAccountSettingsRequestContent = Data.define(:name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"]
        )
      end
    end

    # @generated
    UpdateBoardEntropyRequestContent = Data.define(:auto_postpone_period_in_days) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"]
        )
      end
    end

    # @generated
    UpdateBoardEntropyResponseContent = Data.define

    # @generated
    UpdateBoardInvolvementRequestContent = Data.define(:involvement) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          involvement: data["involvement"]
        )
      end
    end

    # @generated
    UpdateBoardRequestContent = Data.define(:name, :all_access, :auto_postpone_period_in_days, :public_description, :user_ids) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          all_access: data["all_access"],
          auto_postpone_period_in_days: data["auto_postpone_period_in_days"],
          public_description: data["public_description"],
          user_ids: data["user_ids"]
        )
      end
    end

    # @generated
    UpdateBoardResponseContent = Data.define

    # @generated
    UpdateCardRequestContent = Data.define(:title, :description, :column_id, :image, :created_at) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          title: data["title"],
          description: data["description"],
          column_id: data["column_id"],
          image: data["image"],
          created_at: data["created_at"]
        )
      end
    end

    # @generated
    UpdateCardResponseContent = Data.define

    # @generated
    UpdateColumnRequestContent = Data.define(:name, :color) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          color: data["color"]
        )
      end
    end

    # @generated
    UpdateColumnResponseContent = Data.define

    # @generated
    UpdateCommentRequestContent = Data.define(:body) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          body: data["body"]
        )
      end
    end

    # @generated
    UpdateCommentResponseContent = Data.define

    # @generated
    UpdateJoinCodeRequestContent = Data.define(:usage_limit) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          usage_limit: data["usage_limit"]
        )
      end
    end

    # @generated
    UpdateNotificationSettingsRequestContent = Data.define(:bundle_email_frequency) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          bundle_email_frequency: data["bundle_email_frequency"]
        )
      end
    end

    # @generated
    UpdateStepRequestContent = Data.define(:content, :completed) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          content: data["content"],
          completed: data["completed"]
        )
      end
    end

    # @generated
    UpdateStepResponseContent = Data.define

    # @generated
    UpdateUserRequestContent = Data.define(:name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"]
        )
      end
    end

    # @generated
    UpdateUserResponseContent = Data.define

    # @generated
    UpdateUserRoleRequestContent = Data.define(:role) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          role: data["role"]
        )
      end
    end

    # @generated
    UpdateWebhookRequestContent = Data.define(:name, :url, :subscribed_actions) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          name: data["name"],
          url: data["url"],
          subscribed_actions: data["subscribed_actions"]
        )
      end
    end

    # @generated
    UpdateWebhookResponseContent = Data.define

    # @generated
    User = Data.define(:id, :name, :role, :active, :email_address, :created_at, :url, :avatar_url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          role: data["role"],
          active: data["active"],
          email_address: data["email_address"],
          created_at: data["created_at"],
          url: data["url"],
          avatar_url: data["avatar_url"]
        )
      end
    end

    # @generated
    ValidationErrorResponseContent = Data.define(:message, :errors) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          message: data["message"],
          errors: data["errors"]
        )
      end
    end

    # @generated
    Webhook = Data.define(:id, :name, :payload_url, :url, :subscribed_actions, :signing_secret, :active, :created_at, :updated_at, :board) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"],
          payload_url: data["payload_url"],
          url: data["url"],
          subscribed_actions: data["subscribed_actions"],
          signing_secret: data["signing_secret"],
          active: data["active"],
          created_at: data["created_at"],
          updated_at: data["updated_at"],
          board: data["board"]
        )
      end
    end

    # @generated
    WebhookDelivery = Data.define(:id, :state, :created_at, :updated_at, :request, :response, :event) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          state: data["state"],
          created_at: data["created_at"],
          updated_at: data["updated_at"],
          request: data["request"],
          response: data["response"],
          event: data["event"]
        )
      end
    end

    # @generated
    WebhookDeliveryEvent = Data.define(:id, :action, :created_at, :creator, :eventable) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          action: data["action"],
          created_at: data["created_at"],
          creator: data["creator"],
          eventable: data["eventable"]
        )
      end
    end

    # @generated
    WebhookDeliveryEventCreator = Data.define(:id, :name) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          id: data["id"],
          name: data["name"]
        )
      end
    end

    # @generated
    WebhookDeliveryEventEventable = Data.define(:type, :id, :url) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          type: data["type"],
          id: data["id"],
          url: data["url"]
        )
      end
    end

    # @generated
    WebhookDeliveryResponse = Data.define(:code, :error) do
      # @param data [Hash] raw JSON response
      def self.from_json(data)
        new(
          code: data["code"],
          error: data["error"]
        )
      end
    end

  end
end

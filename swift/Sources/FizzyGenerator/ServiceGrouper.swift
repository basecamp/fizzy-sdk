import Foundation

// MARK: - Tag to Service Mapping

/// Maps OpenAPI tags to service class names for Fizzy's 15 services.
let tagToService: [String: String] = [
    "Identity": "Identity",
    "Boards": "Boards",
    "Columns": "Columns",
    "Cards": "Cards",
    "Comments": "Comments",
    "Steps": "Steps",
    "Reactions": "Reactions",
    "Notifications": "Notifications",
    "Tags": "Tags",
    "Users": "Users",
    "Pins": "Pins",
    "Uploads": "Uploads",
    "Webhooks": "Webhooks",
    "Sessions": "Sessions",
    "Devices": "Devices",
    "Untagged": "Miscellaneous",
]

// MARK: - Service Splits

/// Routes operations within a tag to sub-services.
/// Fizzy's services are flat (one tag = one service), so no splits are needed.
let serviceSplits: [String: [String: [String]]] = [:]

// MARK: - Service Definition

struct ServiceDefinition {
    let name: String
    var operations: [ParsedOperation] = []
    var entityTypes: Set<String> = []

    var className: String { "\(name)Service" }
}

// MARK: - OperationId-Based Service Derivation

/// Explicit overrides for operations that don't follow suffix patterns.
private let operationServiceOverrides: [String: String] = [
    "GetMyIdentity": "Identity",
    "CreateDirectUpload": "Uploads",
    "RedeemMagicLink": "Sessions",
    "CompleteSignup": "Sessions",
    "GetNotificationTray": "Notifications",
    "BulkReadNotifications": "Notifications",
    "DeleteCardImage": "Cards",
]

/// Suffix map for deriving service from operationId (longest match first).
private let serviceSuffixes: [(String, String)] = [
    ("CommentReactions", "Reactions"),
    ("CommentReaction", "Reactions"),
    ("CardReactions", "Reactions"),
    ("CardReaction", "Reactions"),
    ("Notifications", "Notifications"),
    ("Notification", "Notifications"),
    ("Comments", "Comments"),
    ("Comment", "Comments"),
    ("Webhooks", "Webhooks"),
    ("Webhook", "Webhooks"),
    ("Columns", "Columns"),
    ("Column", "Columns"),
    ("Boards", "Boards"),
    ("Board", "Boards"),
    ("Cards", "Cards"),
    ("Card", "Cards"),
    ("Steps", "Steps"),
    ("Step", "Steps"),
    ("Users", "Users"),
    ("User", "Users"),
    ("Tags", "Tags"),
    ("Pins", "Pins"),
    ("Session", "Sessions"),
    ("Device", "Devices"),
]

/// Derives service name from operationId when tags are absent.
func deriveServiceName(_ operationId: String) -> String {
    if let override = operationServiceOverrides[operationId] {
        return override
    }
    for (suffix, service) in serviceSuffixes {
        if operationId.hasSuffix(suffix) {
            return service
        }
    }
    return "Miscellaneous"
}

// MARK: - Grouping

/// Groups parsed operations into services based on tags, falling back to operationId heuristic.
func groupOperations(_ operations: [ParsedOperation], schemas: [String: Any]) -> [String: ServiceDefinition] {
    var services: [String: ServiceDefinition] = [:]

    for op in operations {
        let tag = op.tag

        // Determine service name: use tag if mapped, otherwise derive from operationId
        let serviceName: String
        if let mapped = tagToService[tag], tag != "Untagged" {
            if let splits = serviceSplits[tag], !splits.isEmpty {
                var matched: String?
                for svc in splits.keys.sorted() {
                    if splits[svc]!.contains(op.operationId) {
                        matched = svc
                        break
                    }
                }
                serviceName = matched ?? mapped
            } else {
                serviceName = mapped
            }
        } else {
            serviceName = deriveServiceName(op.operationId)
        }

        if services[serviceName] == nil {
            services[serviceName] = ServiceDefinition(name: serviceName)
        }

        services[serviceName]!.operations.append(op)

        // Collect entity types
        if let responseRef = op.responseSchemaRef {
            if let entityName = getEntityTypeName(responseRef, schemas: schemas) {
                services[serviceName]!.entityTypes.insert(entityName)
            }
        }
    }

    return services
}

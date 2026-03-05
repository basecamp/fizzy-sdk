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

// MARK: - Grouping

/// Groups parsed operations into services based on tags.
func groupOperations(_ operations: [ParsedOperation], schemas: [String: Any]) -> [String: ServiceDefinition] {
    var services: [String: ServiceDefinition] = [:]

    for op in operations {
        let tag = op.tag

        // Determine service name
        let serviceName: String
        if let splits = serviceSplits[tag], !splits.isEmpty {
            var matched: String?
            for svc in splits.keys.sorted() {
                if splits[svc]!.contains(op.operationId) {
                    matched = svc
                    break
                }
            }
            serviceName = matched ?? tagToService[tag] ?? tag.replacingOccurrences(of: " ", with: "")
        } else {
            serviceName = tagToService[tag] ?? tag.replacingOccurrences(of: " ", with: "")
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

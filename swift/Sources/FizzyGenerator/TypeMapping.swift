import Foundation

// MARK: - Type Aliases

/// Maps OpenAPI schema names to Swift type names for Fizzy entities.
let typeAliases: [String: (name: String, kind: String)] = [
    "Board": ("Board", "entity"),
    "Card": ("Card", "entity"),
    "Column": ("Column", "entity"),
    "Comment": ("Comment", "entity"),
    "Step": ("Step", "entity"),
    "Reaction": ("Reaction", "entity"),
    "Notification": ("Notification", "entity"),
    "NotificationTray": ("NotificationTray", "entity"),
    "Tag": ("Tag", "entity"),
    "User": ("User", "entity"),
    "Identity": ("Identity", "entity"),
    "Pin": ("Pin", "entity"),
    "DirectUpload": ("DirectUpload", "entity"),
    "Webhook": ("Webhook", "entity"),
    "Session": ("Session", "entity"),
    "Device": ("Device", "entity"),
]

// MARK: - Property Hints

/// Human-friendly descriptions for common body/query property names.
let propertyHints: [String: String] = [
    "title": "Title",
    "body": "Card body content (HTML)",
    "name": "Display name",
    "description": "Description text",
    "color": "Color value",
    "position": "Position for ordering (1-based)",
    "status": "Status filter",
    "email": "Email address",
    "url": "Webhook URL",
    "events": "Event types to subscribe to",
]

// MARK: - Schema -> Swift Type

/// Maps an OpenAPI schema to a Swift type string.
func schemaToSwiftType(_ schema: [String: Any]) -> String {
    if let ref = schema["$ref"] as? String {
        return resolveRef(ref)
    }
    let type = schema["type"] as? String ?? "String"
    switch type {
    case "integer":
        let format = schema["format"] as? String ?? ""
        return format == "int32" ? "Int32" : "Int"
    case "boolean":
        return "Bool"
    case "number":
        return "Double"
    case "array":
        if let items = schema["items"] as? [String: Any] {
            let itemType = schemaToSwiftType(items)
            return "[\(itemType)]"
        }
        return "[Any]"
    case "object":
        if let additionalProperties = schema["additionalProperties"] as? [String: Any] {
            let valueType = schemaToSwiftType(additionalProperties)
            return "[String: \(valueType)]"
        }
        return "[String: Any]"
    default:
        return "String"
    }
}

/// Gets the entity type name for a response schema ref.
func getEntityTypeName(_ schemaRef: String, schemas: [String: Any]) -> String? {
    // Direct entity reference
    if typeAliases[schemaRef] != nil {
        return typeAliases[schemaRef]!.name
    }

    // ResponseContent types -- resolve to underlying entity
    if let entitySchema = findUnderlyingEntitySchema(schemaRef, schemas: schemas) {
        return typeAliases[entitySchema]?.name
    }

    return nil
}

/// Resolves ResponseContent wrapper schemas to their underlying entity schema name.
func findUnderlyingEntitySchema(_ responseSchemaRef: String, schemas: [String: Any]) -> String? {
    guard let schema = schemas[responseSchemaRef] as? [String: Any] else { return nil }

    // Direct $ref to known entity
    if let ref = schema["$ref"] as? String {
        let refName = resolveRef(ref)
        if typeAliases[refName] != nil { return refName }
    }

    // Array with items.$ref to known entity
    if (schema["type"] as? String) == "array",
       let items = schema["items"] as? [String: Any],
       let ref = items["$ref"] as? String {
        let refName = resolveRef(ref)
        if typeAliases[refName] != nil { return refName }
    }

    return nil
}

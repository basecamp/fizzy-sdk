package com.basecamp.fizzy.generator

import kotlinx.serialization.json.*

/**
 * Parses the OpenAPI spec JSON into structured data.
 */
class OpenApiParser(private val root: JsonObject) {
    private val schemas: JsonObject = root["components"]!!
        .jsonObject["schemas"]!!
        .jsonObject

    val paths: JsonObject = root["paths"]!!.jsonObject

    fun resolveRef(ref: String): String = ref.substringAfterLast("/")

    fun getSchema(name: String): JsonObject? = schemas[name]?.jsonObject

    /**
     * Find the underlying entity schema for a ResponseContent type.
     * E.g., "GetCardResponseContent" -> "Card" (via $ref)
     * E.g., "ListCardsResponseContent" -> "Card" (via array items $ref)
     */
    fun findUnderlyingEntitySchema(schemaRef: String): String? {
        val schema = getSchema(schemaRef) ?: return null

        // Direct $ref to a known entity
        val directRef = schema["\$ref"]?.jsonPrimitive?.content
        if (directRef != null) {
            val refName = resolveRef(directRef)
            if (refName in TYPE_ALIASES) return refName
        }

        // Array of entities
        if (schema["type"]?.jsonPrimitive?.content == "array") {
            val itemsRef = schema["items"]?.jsonObject?.get("\$ref")?.jsonPrimitive?.content
            if (itemsRef != null) {
                val refName = resolveRef(itemsRef)
                if (refName in TYPE_ALIASES) return refName
            }
        }

        return null
    }

    /**
     * Resolves a schema property type to a Kotlin type string.
     */
    fun schemaToKotlinType(schema: JsonObject): String {
        val ref = schema["\$ref"]?.jsonPrimitive?.content
        if (ref != null) return "JsonObject"

        return when (schema["type"]?.jsonPrimitive?.content) {
            "integer" -> when (schema["format"]?.jsonPrimitive?.content) {
                "int64" -> "Long"
                else -> "Int"
            }
            "boolean" -> "Boolean"
            "number" -> "Double"
            "array" -> {
                val itemType = schema["items"]?.jsonObject?.let { schemaToKotlinType(it) } ?: "JsonElement"
                "List<$itemType>"
            }
            "object" -> "JsonObject"
            else -> "String"
        }
    }

    /**
     * Gets the Fizzy type hint from x-fizzy-type, if present.
     */
    fun getFizzyType(schema: JsonObject): String? =
        schema["x-fizzy-type"]?.jsonPrimitive?.content
}

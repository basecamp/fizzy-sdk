package com.basecamp.fizzy.generator

/**
 * Generates Kotlin service classes from parsed operation data.
 */
class ServiceEmitter(private val api: OpenApiParser) {

    fun generateService(service: ServiceDefinition): String {
        val sb = StringBuilder()

        // Header
        sb.appendLine("package com.basecamp.fizzy.generated.services")
        sb.appendLine()
        sb.appendLine("import com.basecamp.fizzy.*")
        sb.appendLine("import com.basecamp.fizzy.generated.models.*")
        sb.appendLine("import com.basecamp.fizzy.services.BaseService")
        sb.appendLine("import kotlinx.serialization.json.JsonElement")
        sb.appendLine()
        sb.appendLine("/**")
        sb.appendLine(" * Service for ${service.name} operations.")
        sb.appendLine(" *")
        sb.appendLine(" * @generated from OpenAPI spec -- do not edit directly")
        sb.appendLine(" */")
        sb.appendLine("class ${service.className}(client: AccountClient) : BaseService(client) {")

        for (op in service.operations) {
            sb.appendLine()
            sb.append(generateMethod(op, service.name))
        }

        sb.appendLine("}")

        return sb.toString()
    }

    private fun generateMethod(op: ParsedOperation, serviceName: String): String {
        val sb = StringBuilder()

        val returnType = buildReturnType(op)
        val params = buildParams(op)
        val description = enrichDescription(op.description.lines().first())

        // KDoc
        sb.appendLine("    /**")
        sb.appendLine("     * $description")
        for (p in op.pathParams) {
            sb.appendLine("     * @param ${p.name.snakeToCamelCase()} ${p.description ?: "The ${p.name.toHumanReadable()}"}")
        }
        if (op.bodyProperties.isNotEmpty() && op.bodyContentType == "json") {
            sb.appendLine("     * @param body Request body")
        }
        if (op.bodyContentType == "octet-stream") {
            sb.appendLine("     * @param data Binary file data to upload")
            sb.appendLine("     * @param contentType MIME type of the file")
        }
        for (q in op.queryParams.filter { it.required }) {
            sb.appendLine("     * @param ${q.name.snakeToCamelCase()} ${q.description ?: q.name.toHumanReadable()}")
        }
        if (op.queryParams.any { !it.required } || (op.hasPagination && op.returnsArray)) {
            sb.appendLine("     * @param options Optional query parameters and pagination control")
        }
        sb.appendLine("     */")

        // Method signature
        sb.appendLine("    suspend fun ${op.methodName}($params): $returnType {")

        // Build OperationInfo
        val boardParam = op.pathParams.find { it.name == "boardId" }
        val resourceParam = op.pathParams.find { it.name != "boardId" && it.name.endsWith("Id") || it.name == "cardNumber" }
        val boardArg = if (boardParam != null) "boardId" else "null"
        val resourceArg = if (resourceParam != null) resourceParam.name.snakeToCamelCase() else "null"

        sb.appendLine("        val info = OperationInfo(")
        sb.appendLine("            service = \"$serviceName\",")
        sb.appendLine("            operation = \"${op.operationId}\",")
        sb.appendLine("            resourceType = \"${op.resourceType}\",")
        sb.appendLine("            isMutation = ${op.isMutation},")
        sb.appendLine("            boardId = $boardArg,")
        sb.appendLine("            resourceId = $resourceArg,")
        sb.appendLine("        )")

        // Build path with interpolated params
        val pathExpr = buildPathExpression(op)

        // Emit query string building if the operation has query params
        val hasQueryParams = op.queryParams.isNotEmpty()
        if (hasQueryParams) {
            sb.append(generateQueryBuilding(op))
        }
        val pathWithQuery = if (hasQueryParams) "$pathExpr + qs" else pathExpr

        val isPaginated = op.hasPagination && op.returnsArray

        if (isPaginated) {
            val entitySchema = op.responseSchemaRef?.let { api.findUnderlyingEntitySchema(it) }
            val entityType = entitySchema?.let { TYPE_ALIASES[it] } ?: "JsonElement"

            // Convert custom options to PaginationOptions
            val hasOptionalQuery = op.queryParams.any { !it.required }
            val optionsArg = if (hasOptionalQuery) "options?.toPaginationOptions()" else "options"

            val paginatedSuffix = if (op.isAccountScoped) "" else "Root"
            sb.appendLine("        return requestPaginated(info, $optionsArg, {")
            sb.appendLine("            httpGet$paginatedSuffix($pathWithQuery, operationName = info.operation)")
            sb.appendLine("        }) { body ->")
            sb.appendLine("            json.decodeFromString<List<$entityType>>(body)")
            sb.appendLine("        }")
        } else if (op.returnsVoid) {
            sb.appendLine("        request(info, {")
            sb.append(generateHttpCall(op, pathWithQuery))
            sb.appendLine("        }) { Unit }")
        } else {
            val entitySchema = op.responseSchemaRef?.let { api.findUnderlyingEntitySchema(it) }
            val entityType = entitySchema?.let { TYPE_ALIASES[it] }
            val decodeType = when {
                entityType != null && op.returnsArray -> "List<$entityType>"
                entityType != null -> entityType
                else -> "JsonElement"
            }

            sb.appendLine("        return request(info, {")
            sb.append(generateHttpCall(op, pathWithQuery))
            sb.appendLine("        }) { body ->")
            sb.appendLine("            json.decodeFromString<$decodeType>(body)")
            sb.appendLine("        }")
        }

        sb.appendLine("    }")

        return sb.toString()
    }

    /**
     * Generates query string building code that calls BaseService.buildQueryString().
     */
    private fun generateQueryBuilding(op: ParsedOperation): String {
        val sb = StringBuilder()
        sb.appendLine("        val qs = buildQueryString(")
        for (q in op.queryParams) {
            val camelName = q.name.snakeToCamelCase()
            val accessor = if (q.required) camelName else "options?.$camelName"
            sb.appendLine("            \"${q.name}\" to $accessor,")
        }
        sb.appendLine("        )")
        return sb.toString()
    }

    private fun generateHttpCall(op: ParsedOperation, pathWithQuery: String): String {
        val sb = StringBuilder()
        val suffix = if (op.isAccountScoped) "" else "Root"

        when (op.httpMethod) {
            "GET" -> sb.appendLine("            httpGet$suffix($pathWithQuery, operationName = info.operation)")
            "POST" -> {
                if (op.bodyContentType == "octet-stream") {
                    sb.appendLine("            httpPostBinary($pathWithQuery, data, contentType)")
                } else if (op.bodyContentType == "json" && op.bodyProperties.isNotEmpty()) {
                    sb.appendLine("            httpPost$suffix($pathWithQuery, json.encodeToString(${buildBodySerializer(op)}), operationName = info.operation)")
                } else {
                    sb.appendLine("            httpPost$suffix($pathWithQuery, operationName = info.operation)")
                }
            }
            "PUT" -> {
                val bodyArg = if (op.bodyContentType == "json" && op.bodyProperties.isNotEmpty()) {
                    ", json.encodeToString(${buildBodySerializer(op)})"
                } else {
                    ""
                }
                sb.appendLine("            httpPut$suffix($pathWithQuery$bodyArg, operationName = info.operation)")
            }
            "DELETE" -> sb.appendLine("            httpDelete$suffix($pathWithQuery, operationName = info.operation)")
            "PATCH" -> {
                val bodyArg = if (op.bodyContentType == "json" && op.bodyProperties.isNotEmpty()) {
                    ", json.encodeToString(${buildBodySerializer(op)})"
                } else {
                    ""
                }
                sb.appendLine("            httpPatch$suffix($pathWithQuery$bodyArg, operationName = info.operation)")
            }
        }

        return sb.toString()
    }

    private fun buildPathExpression(op: ParsedOperation): String {
        // Replace path params like {projectId} with $projectId
        var path = op.path
        for (p in op.pathParams) {
            path = path.replace("{${p.name}}", "\${${p.name.snakeToCamelCase()}}")
        }
        return "\"$path\""
    }

    private fun buildBodySerializer(op: ParsedOperation): String {
        val props = op.bodyProperties
        if (props.isEmpty()) return "kotlinx.serialization.json.JsonObject(emptyMap())"

        val sb = StringBuilder()
        sb.appendLine("kotlinx.serialization.json.buildJsonObject {")
        for (p in props) {
            val camelName = p.name.snakeToCamelCase()
            val accessor = "body.$camelName"
            when {
                !p.required -> {
                    sb.appendLine("                $accessor?.let { put(\"${p.name}\", ${jsonPutExpression(p.type, "it")}) }")
                }
                else -> {
                    sb.appendLine("                put(\"${p.name}\", ${jsonPutExpression(p.type, accessor)})")
                }
            }
        }
        sb.append("            }")
        return sb.toString()
    }

    private fun jsonPutExpression(type: String, accessor: String): String = when (type) {
        "String" -> "kotlinx.serialization.json.JsonPrimitive($accessor)"
        "Int", "Long" -> "kotlinx.serialization.json.JsonPrimitive($accessor)"
        "Boolean" -> "kotlinx.serialization.json.JsonPrimitive($accessor)"
        "Double" -> "kotlinx.serialization.json.JsonPrimitive($accessor)"
        "JsonObject" -> "$accessor"
        else -> {
            if (type == "List<JsonObject>") {
                "kotlinx.serialization.json.JsonArray($accessor)"
            } else if (type.startsWith("List<")) {
                "kotlinx.serialization.json.JsonArray($accessor.map { kotlinx.serialization.json.JsonPrimitive(it) })"
            } else {
                "kotlinx.serialization.json.JsonPrimitive($accessor.toString())"
            }
        }
    }

    private fun buildReturnType(op: ParsedOperation): String {
        if (op.returnsVoid) return "Unit"

        val entitySchema = op.responseSchemaRef?.let { api.findUnderlyingEntitySchema(it) }
        val entityType = entitySchema?.let { TYPE_ALIASES[it] }

        return when {
            entityType != null && op.returnsArray && op.hasPagination -> "ListResult<$entityType>"
            entityType != null && op.returnsArray -> "List<$entityType>"
            op.returnsArray && op.hasPagination -> "ListResult<JsonElement>"
            entityType != null -> entityType
            else -> "JsonElement"
        }
    }

    private fun buildParams(op: ParsedOperation): String {
        val parts = mutableListOf<String>()

        // Path params
        for (p in op.pathParams) {
            parts += "${p.name.snakeToCamelCase()}: ${p.type}"
        }

        // Body param
        if (op.bodyContentType == "json" && op.bodyProperties.isNotEmpty()) {
            val bodyClassName = buildBodyClassName(op)
            parts += "body: $bodyClassName"
        }

        // Binary upload
        if (op.bodyContentType == "octet-stream") {
            parts += "data: ByteArray"
            parts += "contentType: String"
        }

        // Required query params
        for (q in op.queryParams.filter { it.required }) {
            parts += "${q.name.snakeToCamelCase()}: ${q.type}"
        }

        // Optional: query params + pagination
        val hasOptionalQuery = op.queryParams.any { !it.required }
        val hasPagination = op.hasPagination && op.returnsArray
        if (hasOptionalQuery || hasPagination) {
            val optionsClassName = buildOptionsClassName(op, hasPagination, hasOptionalQuery)
            parts += "options: $optionsClassName? = null"
        }

        return parts.joinToString(", ")
    }

    private fun buildBodyClassName(op: ParsedOperation): String =
        "${op.operationId}Body"

    private fun buildOptionsClassName(op: ParsedOperation, hasPagination: Boolean, hasOptionalQuery: Boolean): String =
        when {
            hasPagination && !hasOptionalQuery -> "PaginationOptions"
            else -> "${op.operationId}Options"
        }

    private fun enrichDescription(desc: String): String {
        var result = desc.replace(Regex("""\s*\(returns \d+ [^)]+\)"""), "")
        return result
    }
}

private fun String.toHumanReadable(): String {
    if (endsWith("Id")) {
        return removeSuffix("Id")
            .replace(Regex("([a-z])([A-Z])"), "$1 $2")
            .lowercase() + " ID"
    }
    if (this == "cardNumber") return "card number"
    return replace("_", " ")
        .replace(Regex("([a-z])([A-Z])"), "$1 $2")
        .lowercase()
}

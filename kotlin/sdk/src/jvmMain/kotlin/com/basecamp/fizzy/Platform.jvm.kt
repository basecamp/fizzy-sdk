package com.basecamp.fizzy

import java.util.concurrent.ConcurrentHashMap

@PublishedApi
internal actual fun <V> createServiceCache(): MutableMap<String, V> = ConcurrentHashMap()

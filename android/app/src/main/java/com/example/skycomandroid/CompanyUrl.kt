package com.example.skycomandroid

import java.net.URI
import java.net.URISyntaxException

/**
 * Parses the company-scoped mobile paths. Company ids are UUIDs
 * (PostgreSQL uuidv7), not numeric ids.
 */
object CompanyUrl {
    private val COMPANY_PATH = Regex(
        """/mobile/companies/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:/|$)""",
        RegexOption.IGNORE_CASE
    )

    fun companyId(url: String?): String? {
        val path = path(url) ?: return null
        return COMPANY_PATH.find(path)?.groupValues?.get(1)
    }

    fun isSignIn(url: String?): Boolean {
        val path = path(url) ?: return false
        return path == "/mobile/sign_in" || path == "/mobile/sign_in/"
    }

    fun isMobileHome(url: String?): Boolean {
        val path = path(url) ?: return false
        return path == "/mobile/home" || path == "/mobile/home/"
    }

    private fun path(url: String?): String? {
        if (url.isNullOrBlank()) return null

        return try {
            URI(url).path
        } catch (_: URISyntaxException) {
            null
        }
    }
}

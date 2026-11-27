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

    /**
     * True when [url] has the same scheme, host and port as the configured app
     * origin. Used to keep the JS bridge unavailable to external pages.
     */
    fun isAppOrigin(url: String?, baseUrl: String): Boolean {
        if (url.isNullOrBlank() || baseUrl.isBlank()) return false

        return try {
            val target = URI(url)
            val base = URI(baseUrl)
            val targetHost = target.host ?: return false
            val baseHost = base.host ?: return false

            target.scheme.equals(base.scheme, ignoreCase = true) &&
                targetHost.equals(baseHost, ignoreCase = true) &&
                target.port == base.port
        } catch (_: URISyntaxException) {
            false
        }
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

package com.example.skycomandroid

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CompanyUrlTest {
    private val companyId = "01a17d45-cc1e-79a8-aa01-c8e2868e9cf3"

    @Test
    fun extractsCompanyIdFromScopedPath() {
        assertEquals(
            companyId,
            CompanyUrl.companyId("http://10.88.0.2:3000/mobile/companies/$companyId/home")
        )
    }

    @Test
    fun extractsCompanyIdFromRelativePath() {
        assertEquals(
            companyId,
            CompanyUrl.companyId("/mobile/companies/$companyId/attendance_month?month=2026-09")
        )
    }

    @Test
    fun ignoresNonCompanyPaths() {
        assertNull(CompanyUrl.companyId("http://10.88.0.2:3000/mobile/sign_in"))
        assertNull(CompanyUrl.companyId("http://10.88.0.2:3000/mobile/home"))
        assertNull(CompanyUrl.companyId("http://10.88.0.2:3000/mobile/companies/current/home"))
        assertNull(CompanyUrl.companyId(null))
    }

    @Test
    fun detectsSignInAndFallbackHome() {
        assertTrue(CompanyUrl.isSignIn("http://10.88.0.2:3000/mobile/sign_in"))
        assertTrue(CompanyUrl.isMobileHome("http://10.88.0.2:3000/mobile/home"))
        assertFalse(CompanyUrl.isSignIn("http://10.88.0.2:3000/mobile/companies/$companyId/home"))
    }
}

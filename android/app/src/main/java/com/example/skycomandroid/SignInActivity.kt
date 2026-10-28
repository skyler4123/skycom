package com.example.skycomandroid

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import dev.hotwire.core.turbo.errors.VisitError
import dev.hotwire.core.turbo.webview.WebViewInfo
import dev.hotwire.core.turbo.webview.WebViewVersionCompatibility
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

/**
 * Unauthenticated entry point. It has no bottom navigation; the only thing it
 * does is load /mobile/sign_in and, once Rails redirects to a company-scoped
 * page, persist that company id and launch [MainActivity].
 */
class SignInActivity : HotwireActivity(), MobileWebListener {
    private var transitioning = false

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        // Fast path: an authenticated shell can start directly with the stored
        // company. MainActivity returns here if the session has expired.
        CompanyStore.read(this)?.let { companyId ->
            startMainActivity(companyId)
            return
        }

        setContentView(R.layout.activity_sign_in)
        findViewById<View>(R.id.sign_in_root).applyDefaultImeWindowInsets()

        WebViewVersionCompatibility.displayUpdateDialogIfOutdated(
            activity = this,
            requiredVersion = WebViewInfo.REQUIRED_WEBVIEW_VERSION
        )
    }

    override fun navigatorConfigurations(): List<NavigatorConfiguration> = listOf(
        NavigatorConfiguration(
            name = "sign_in",
            startLocation = "${BuildConfig.BASE_URL}/mobile/sign_in",
            navigatorHostId = R.id.sign_in_navigator_host
        )
    )

    override fun onMobileWebLocationChanged(url: String?) {
        if (transitioning) return

        val companyId = CompanyUrl.companyId(url)
        if (companyId != null) {
            startMainActivity(companyId)
            return
        }

        // The sign-in page or the no-employee fallback means there is no
        // usable company; drop any stale value.
        if (CompanyUrl.isSignIn(url) || CompanyUrl.isMobileHome(url)) {
            CompanyStore.clear(this)
        }
    }

    override fun onMobileWebError(error: VisitError) {
        // Stay on this activity; Hotwire renders the error/retry view.
    }

    private fun startMainActivity(companyId: String) {
        if (transitioning) return
        transitioning = true
        CompanyStore.write(this, companyId)

        startActivity(
            Intent(this, MainActivity::class.java)
                .putExtra(MainActivity.EXTRA_COMPANY_ID, companyId)
        )
        finish()
    }
}
